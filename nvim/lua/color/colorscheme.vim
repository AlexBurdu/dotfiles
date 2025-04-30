" ### UI Settings###
set cursorline
let timehour = (strftime("%H"))
if timehour >= 20 || timehour < 5
  set background=dark
  colorscheme carbonfox
else
  set background=light
  colorscheme dayfox
endif

