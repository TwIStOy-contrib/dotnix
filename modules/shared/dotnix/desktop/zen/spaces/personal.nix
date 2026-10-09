{
  personal = {
    id = "58cf0d56-8221-4939-8277-354456d1ea7f";
    name = "Personal";
    icon = "🏠";
    position = 1000;
    container = 1;

    pins.github = {
      id = "0b7454d6-3978-45c4-ad57-a236b3b46fd6";
      title = "GitHub";
      url = "https://github.com/";
      container = 1;
    };

    # matchType defaults to "contains"; openIn/id are derived from the space.
    routes.github.reference = "github.com";
  };
}
