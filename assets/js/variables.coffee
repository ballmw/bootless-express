App.Variables = class Variables
  toLess: (params) ->
    "@linkColor: " + ( params.linkColor == "undefined" ? "#0069d6;" : params.linkColor) + "\n" + "@linkColorHover: darken(@linkColor, 15);"