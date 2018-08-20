unproject <- function(x,y){
  d <- 180.0/pi
  R <- 6378137.0
  lat <- (2 * atan(exp(y/R)) - pi/2)*d
  lng <- x*d/R
  list(lat = lat, lng = lng)
}

vs2LatLng <- function(x_vs,y_vs,center,length){
  center <- unlist(center)
  length <- unlist(length)
  ratio <- 2*20037508.34/length
  x <- (x_vs - center[1]) * ratio
  y <- (y_vs - center[2]) * ratio
  unproject(x,y)
}

addLatLng <- function(df, center, length){
  for(row in 1:nrow(df)){
    ll <- vs2LatLng(df$x_vs[row], df$y_vs[row], center, length)
    df$lat[row] <- ll$lat
    df$lng[row] <- ll$lng
  }
  df
}

vsLength2geoLength <- function(length, x_vs, y_vs, surface){
  ll <- vs2LatLng(x_vs, y_vs, surface$center, surface$length)
  lat <- ll$lat
  gLength <- geoArc(lat)
  gLength * length/surface$length
}

geoArc <- function(lat){
  R <- 6378137.0
  2 * R * pi * cos(lat * pi / 180)
}