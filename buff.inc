struc string [data] {
  common
  . db data
  .len = $ - .
}

struc arr size {
  repeat size
  db 0
  end repeat
  .len = size
}

