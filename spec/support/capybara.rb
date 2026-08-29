# GitHub Actions and other CI runners need extra Chrome flags; headed mode does not work without a display.
if ENV["CI"]
  Capybara.register_driver :selenium_chrome_headless do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1400,900")
    options.add_argument("--remote-allow-origins=*")

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end
end
