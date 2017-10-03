/* global L */

L.Icon.Default.imagePath = '/images'

const offsets = {
  12: 0.01,
  13: 0.005,
  14: 0.0025,
  15: 0.001,
  16: 0.0005,
  17: 0.00025,
  18: 0.0001
}

function setup_map() {
  const div = $('#map')
  if (div.length > 0) {
    const zoom = div.data('zoom')
    const map_voffset = offsets[zoom] // shift center down just a bit to go under heading
    const lat = div.data('latitude')
    const lon = div.data('longitude')
    const map = L.map(
      'map',
      {
        center: [lat + map_voffset, lon],
        zoom,
        zoomControl: false
      }
    )
    const tiles = L.tileLayer(
      "//a.tile.openstreetmap.org/{z}/{x}/{y}.png",
      {
        attribution: div.data('notice'),
        maxZoom: 18
      }
    )
    tiles.addTo(map)
    // L.control.zoom(position: 'bottomright').addTo(map)
    const marker = L.marker([lat, lon]).addTo(map)
    marker.bindPopup("<p>#{div.data('address')}</p>") // data-address must be sanitized already
  }
}

function setup_directory_map() {
  const div = $('#directory_map')
  if (div.length > 0) {
    const excl_height = $('.header').outerHeight() + $('.content-header').outerHeight() + $('.footer').outerHeight()
    const padding = 40
    $('#directory_map').height($(window).height() - (excl_height + padding)) // set height of map div

    const map = L.map('directory_map')
    const tiles = L.tileLayer(
      "//a.tile.openstreetmap.org/{z}/{x}/{y}.png",
      {
        attribution: div.data('notice'),
        maxZoom: 18
      }
    )
    tiles.addTo(map)
    $.getJSON("/directory_maps/family_locations.json", (marker_data) => {
      if (marker_data.length > 0) {
        const markers = new L.MarkerClusterGroup
        marker_data.forEach((data) => {
          const marker = L.marker(new L.LatLng(data.latitude, data.longitude), { title: data.name })
          marker.bindPopup('<a href="/families/' + data.id + '">' +  data.name + '</a>')
          markers.addLayer(marker)
        })
        map.addLayer(markers)
        map.fitBounds(markers, { maxZoom: 15 })
      }
    })
  }
}

setup_map()
setup_directory_map()
