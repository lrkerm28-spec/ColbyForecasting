source("setup.R")
db = brickman_database()


db = db |>
  filter(scenario == "PRESENT", interval == "mon")
covars = read_brickman(db)
x = read_model_input(scientificname = "Halichoerus grypus")


result = x |>
  group_by(month) |>
  group_map(
  function(rows, keys){
    first = slice(rows, 1)
    last = slice(rows, nrow(rows))
    r = bind_rows(first, last)
    cv = slice(covars, "month", rows$month[1])
    vals = extract_brickman(cv,r, form = "wide") |>
      select(-.id)
    return(vals)
    }, .keep = TRUE
    ) |>
  bind_rows()
  