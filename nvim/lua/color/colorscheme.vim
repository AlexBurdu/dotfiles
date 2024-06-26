" ### UI Settings###
let timehour = (strftime("%H"))
if timehour >= 19 || timehour < 5
  set background=dark
else
  set background=light
endif

