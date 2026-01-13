
read_observations = function(scientificname = "Halichoerus grypus",
                             minimum_year = 1970, individual_number, 
                             date, eventyear,
                             ...){
  
  #' Read raw OBIS data and then filter it
  #' 
  #' @param scientificname chr, the name of the species to read
  #' @param minimum_year num, the earliest year of observation to accept or 
  #'   set to NULL to skip
  #' @param ... other arguments passed to `read_obis()`
  #' @return a filtered table of observations
  
  # Happy coding!
  
  # read in the raw data
  x = read_obis(scientificname, ...) |>
    dplyr::mutate(month = factor(month, levels = month.abb))
  
  # if the user provided a non-NULL filter by year
  if (!is.null(minimum_year)){
    x = x |>
      filter(year >= minimum_year)
  }

  if(individual_number == 1)
    {
    x = x |>
    filter(!is.na(individualCount))
  }
  if(date == 1)
  {
    x = x |>
    filter(!is.na(eventDate))  
  }
  if(eventyear == 1)
  {
  x = x |>
  filter(!is.na(year))
  }
  
  return(x)
  
  
}
#source("setup.R")
#obs = read_observations()
#summary(obs)
#