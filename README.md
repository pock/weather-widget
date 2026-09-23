# Weather Widget
Stay updated with the latest weather forecast for your location, displayed directly into your Touch Bar.

# Preview
<img src="https://pock.app/_nuxt/img/pock_weather_widget.584df8f.png" height="60">

# Data
Weather data is provided by [Open-Meteo](https://open-meteo.com) (free, no API key required).

The list of selectable cities lives in [`Weather/cities.csv`](Weather/cities.csv). It has no header row; each line is:

```
name,latitude,longitude,country,population
```

`population` is informational only and is not used by the widget. Names must not contain commas. To add a missing city, append a line with its coordinates in decimal degrees (e.g. from the [Open-Meteo geocoding API](https://geocoding-api.open-meteo.com/v1/search?name=Adelaide)).
