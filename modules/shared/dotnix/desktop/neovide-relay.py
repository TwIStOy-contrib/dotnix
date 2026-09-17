#!/usr/bin/env python3
"""Local stand-in for a remote nvim --listen address.

Neovide dials --listen. Upstream is an et forward of the remote nvim port.
:restart tells the UI to attach to a new listen address on the remote host,
so this process opens another et forward and the next connection goes there.
"""

import argparse
import select
import socket
import subprocess
import threading
import time

DIAL_TIMEOUT_S = 30
BUF_LIMIT = 1 << 20


def main():
    args = parse_args()
    relay = Relay(args)
    relay.serve()


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--listen", required=True, help="address neovide dials")
    parser.add_argument("--upstream", required=True, help="current et forward")
    parser.add_argument("--remote-port", required=True, help="port the first nvim listens on")
    parser.add_argument("--host", required=True, help="et host to forward new ports from")
    return parser.parse_args()


class Relay:
    def __init__(self, args):
        self.upstream = [args.upstream]
        self.remote_port = args.remote_port
        self.et_host = args.host
        self.forwards = {}
        host, port = args.listen.rsplit(":", 1)
        self.listener = socket.socket()
        self.listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.listener.bind((host, int(port)))
        self.listener.listen(1)

    def serve(self):
        while True:
            readable, _, _ = select.select([self.listener], [], [], 1)
            if not readable:
                continue
            client, _ = self.listener.accept()
            threading.Thread(target=self.serve_client, args=(client,), daemon=True).start()

    def serve_client(self, client):
        remote = self.dial()
        if remote is None:
            client.close()
            return
        # Copy until either socket dies, then close both. :detach does not
        # produce a local EOF through an et forward: nvim sends error_exit and
        # half-closes, and the forward keeps the read side up. Neovide only
        # reconnects after this socket actually closes.
        done = threading.Event()
        threading.Thread(
            target=self.copy, args=(client, remote, False, done), daemon=True
        ).start()
        self.copy(remote, client, True, done)
        client.close()
        remote.close()

    def copy(self, src, dst, scan, done):
        # Forward each read unchanged. Neovide's reader already assembles a
        # short read into a full msgpack value; rewriting the cuts makes it
        # treat one read as a finished message and either panic or paint a
        # broken grid. Restart scanning keeps its own buffer.
        pending = b""
        try:
            while not done.is_set():
                try:
                    chunk = src.recv(65536)
                except socket.timeout:
                    continue
                except OSError:
                    return
                if not chunk:
                    return
                try:
                    dst.sendall(chunk)
                except OSError:
                    return
                if not scan:
                    continue
                pending += chunk
                complete, pending = split_messages(pending)
                if complete and self.note_restart(complete):
                    return
        finally:
            done.set()

    def dial(self):
        deadline = time.monotonic() + DIAL_TIMEOUT_S
        while time.monotonic() < deadline:
            for addr in list(self.upstream):
                try:
                    sock = socket.create_connection(addr.rsplit(":", 1), 0.2)
                except OSError:
                    continue
                return sock
            time.sleep(0.05)
        return None

    def note_restart(self, buf):
        # redraw "restart" is ["restart", [<listen-addr>]], packed as
        # fixstr "restart" immediately followed by a 1-element array whose
        # element is the address. Scanning the raw bytes for either token
        # matches ordinary grid text and makes Neovide drop the session.
        #
        # :detach sends ["error_exit", [0]] and then closes the UI channel.
        # The close does not survive an et forward, so the relay has to drop
        # the session itself once that event has been forwarded.
        detach = b"\xaaerror_exit\x91" in buf
        for packed in (b"\xa7restart\x91",):
            start = 0
            while True:
                at = buf.find(packed, start)
                if at < 0:
                    break
                addr = trailing_addr(buf, at + len(packed))
                mapped = self.local_addr(addr) if addr else None
                if mapped and mapped not in self.upstream:
                    self.upstream.insert(0, mapped)
                start = at + len(packed)
        return detach

    def local_addr(self, addr):
        remote = addr.rsplit(":", 1)[1]
        if remote == self.remote_port:
            return self.upstream[-1]
        return self.forward_to(remote)

    def forward_to(self, remote):
        if remote in self.forwards:
            return self.forwards[remote]
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            local = probe.getsockname()[1]
        subprocess.Popen(
            ["et", self.et_host, "-N", "-t", f"{local}:{remote}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        mapped = f"127.0.0.1:{local}"
        self.forwards[remote] = mapped
        return mapped


def split_messages(buf):
    """Return bytes through the last complete msgpack value, and the rest.

    None for the first item means the buffer ends inside a value.
    """
    end = 0
    while end < len(buf):
        nxt = msgpack_end(buf, end)
        if nxt is None:
            return (buf[:end] or None), buf[end:]
        end = nxt
    return buf, b""


def msgpack_end(buf, i):
    if i >= len(buf):
        return None
    kind = buf[i]
    i += 1
    if kind <= 0x7F or kind >= 0xE0 or kind in (0xC0, 0xC2, 0xC3):
        return i
    if kind == 0xCC or kind == 0xD0:
        return i + 1 if i + 1 <= len(buf) else None
    if kind in (0xCD, 0xD1):
        return i + 2 if i + 2 <= len(buf) else None
    if kind in (0xCE, 0xD2, 0xCA):
        return i + 4 if i + 4 <= len(buf) else None
    if kind in (0xCF, 0xD3, 0xCB):
        return i + 8 if i + 8 <= len(buf) else None
    if kind == 0xC4 or kind == 0xD9:
        return after_len(buf, i, 1)
    if kind == 0xC5 or kind == 0xDA:
        return after_len(buf, i, 2)
    if kind == 0xC6 or kind == 0xDB:
        return after_len(buf, i, 4)
    if kind & 0xE0 == 0xA0:
        n = kind & 0x1F
        return i + n if i + n <= len(buf) else None
    if kind & 0xF0 == 0x90:
        return after_items(buf, i, kind & 0x0F)
    if kind & 0xF0 == 0x80:
        return after_items(buf, i, (kind & 0x0F) * 2)
    if kind == 0xDC:
        return after_count(buf, i, 2, 1)
    if kind == 0xDD:
        return after_count(buf, i, 4, 1)
    if kind == 0xDE:
        return after_count(buf, i, 2, 2)
    if kind == 0xDF:
        return after_count(buf, i, 4, 2)
    if kind == 0xD4:
        return i + 2 if i + 2 <= len(buf) else None
    if kind == 0xD5:
        return i + 3 if i + 3 <= len(buf) else None
    if kind == 0xD6:
        return i + 5 if i + 5 <= len(buf) else None
    if kind == 0xD7:
        return i + 9 if i + 9 <= len(buf) else None
    if kind == 0xD8:
        return i + 17 if i + 17 <= len(buf) else None
    if kind == 0xC7:
        return after_ext(buf, i, 1)
    if kind == 0xC8:
        return after_ext(buf, i, 2)
    if kind == 0xC9:
        return after_ext(buf, i, 4)
    return None


def after_len(buf, i, width):
    if i + width > len(buf):
        return None
    n = int.from_bytes(buf[i : i + width], "big")
    end = i + width + n
    return end if end <= len(buf) else None


def after_ext(buf, i, width):
    if i + width + 1 > len(buf):
        return None
    n = int.from_bytes(buf[i : i + width], "big")
    end = i + width + 1 + n
    return end if end <= len(buf) else None


def after_count(buf, i, width, each):
    if i + width > len(buf):
        return None
    n = int.from_bytes(buf[i : i + width], "big")
    return after_items(buf, i + width, n * each)


def after_items(buf, i, n):
    for _ in range(n):
        i = msgpack_end(buf, i)
        if i is None:
            return None
    return i


def trailing_addr(buf, start):
    if start < 0 or start >= len(buf):
        return None
    kind = buf[start]
    if kind & 0xE0 == 0xA0:
        length = kind & 0x1F
        start += 1
    elif kind == 0xD9 and start + 1 < len(buf):
        length = buf[start + 1]
        start += 2
    else:
        return None
    end = start + length
    if end > len(buf):
        return None
    try:
        addr = buf[start:end].decode()
    except UnicodeDecodeError:
        return None
    if not (addr.startswith("127.0.0.1:") or addr.startswith("localhost:")):
        return None
    port = addr.rsplit(":", 1)[1]
    if not port.isdigit():
        return None
    return addr


if __name__ == "__main__":
    main()
