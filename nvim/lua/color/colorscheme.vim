" ### UI Settings###
let timehour = (strftime("%H"))
if timehour >= 19 || timehour < 5
  set background=dark
  colorscheme carbonfox
else
  set background=light
  colorscheme PaperColor
endif

