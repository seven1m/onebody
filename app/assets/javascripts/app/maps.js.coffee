L.Icon.Default.imagePath = '/images'

offsets = 
  12: 0.01
  13: 0.005
  14: 0.0025
  15: 0.001
  16: 0.0005
  17: 0.00025
  18: 0.0001

if (div = $('#map')).length > 0
  zoom = div.data('zoom')
  map_voffset = offsets[zoom] # shift center down just a bit to go under heading
  lat = div.data('latitude')
  lon = div.data('longitude')
  protocol = div.data('protocol')
  map = L.map 'map',
    center: [lat + map_voffset, lon],
    zoom: zoom
    zoomControl: false
  tiles = L.tileLayer "#{protocol}://a.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: div.data('notice')
    maxZoom: 18
  tiles.addTo(map)
  #L.control.zoom(position: 'bottomright').addTo(map)
  marker = L.marker([lat, lon]).addTo(map)
  marker.bindPopup("<p>#{div.data('address')}</p>") # data-address must be sanitized already
