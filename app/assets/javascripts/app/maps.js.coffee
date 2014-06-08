L.Icon.Default.imagePath = '/assets'

if (div = $('#map')).length > 0
  lat = div.data('latitude')
  lon = div.data('longitude')
  map = L.map('map').setView([lat, lon], 13)
  tiles = L.tileLayer 'http://otile1.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpg',
    attribution: div.data('notice')
    maxZoom: 18
  tiles.addTo(map)
  marker = L.marker([lat, lon]).addTo(map)
