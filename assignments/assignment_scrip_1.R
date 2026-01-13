source("setup.R")

buoys = gom_buoys()
coast = read_coastline()
db = brickman_database()

# filter the buoys to pull out just N01
buoys = buoys |> 
  filter(id == "M01")
db = db |> 
  filter(scenario == "PRESENT", interval == "mon")
covars = read_brickman(db)
x = extract_brickman(covars, buoys, form = "wide")
x = x |>
  mutate(month = factor(month, levels = month.abb))
ggplot(data = x,
       mapping = aes(x = month, y = SST)) +
  geom_point() + 
  labs(title = "RCP45 2055 at buoy M01")

# bonus... save the image
ggsave("images/M01_dT.png")
