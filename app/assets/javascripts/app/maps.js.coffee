L.Icon.Default.imagePath = '/images'

map_voffset = 0.01 # shift center down just a bit to go under heading

if (div = $('#map')).length > 0
  lat = div.data('latitude')
  lon = div.data('longitude')
  protocol = div.data('protocol')
  map = L.map 'map',
    center: [lat + map_voffset, lon],
    zoom: 13
    zoomControl: false
  tiles = L.tileLayer "#{protocol}://a.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: div.data('notice')
    maxZoom: 18
  tiles.addTo(map)
  #L.control.zoom(position: 'bottomright').addTo(map)
  marker = L.marker([lat, lon]).addTo(map)
  marker.bindPopup("<p>#{div.data('address')}</p>") # data-address must be sanitized already
