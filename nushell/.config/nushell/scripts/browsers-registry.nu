# Registry of known browsers: desktop-file prefix, actual binary, private-window flag
const BROWSER_REGISTRY = [
    {appid: "google-chrome", bin: "google-chrome", private_flag: "--incognito"}
    {appid: "brave-browser", bin: "brave-browser", private_flag: "--incognito"}
    {appid: "chromium", bin: "chromium", private_flag: "--incognito"}
    {appid: "firefox", bin: "firefox", private_flag: "--private-window"}
    {appid: "librewolf", bin: "librewolf", private_flag: "--private-window"}
    {appid: "waterfox", bin: "waterfox", private_flag: "--private-window"}
    {appid: "zen", bin: "zen", private_flag: "--private-window"}
]

# Look up a browser entry in the registry by matching the xdg desktop-file class
export def get-browser [] {
    let desktop_class = xdg-settings get default-web-browser | str trim

    (try {$BROWSER_REGISTRY
    | where {|row| $desktop_class | str starts-with $row.appid}
    | first
    } catch {
        null
    })
}

# Returns default browser class
export def get-browser-appid [] {
    let browser = get-browser

    if ($browser | is-empty) {
        null
        return
    }

    $browser.appid
}

# Tries to open a default browser from xdg-settings with flags
export def open-browser [url: string, --private] {
    let browser = get-browser

    if ($browser | is-empty) {
        print -e $"Unknown default browser, falling back to xdg-open"
        xdg-open $url
        return
    }

    if not ($private) {
        run-external $browser.bin $url
    } else {
        run-external $browser.bin $browser.private_flag $url
    }
}
