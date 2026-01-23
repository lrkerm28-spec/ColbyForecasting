Assignment 4
================

``` r
knitr::opts_chunk$set(echo = TRUE)
source("/home/lrkerm28/ColbyForecasting/setup.R")
```

## Load Data

The first step is to load the necessary data we need in order to create
models based on the obis Grey Seal data.

``` r
cfg = read_configuration(scientificname = "Halichoerus grypus", version = "v1")
model_input = read_model_input(scientificname = "Halichoerus grypus", 
                               version = "v1",
                               log_me = c("depth", "Xbtm")) |>
  dplyr::mutate(month = month_as_number(.data$month)) |>
  select(all_of(c("class", cfg$keep)))
```

## Splitting the data into groups

Next, we want to split the data into two groups: data for training the
model during creation and data for testing the model after we have
created it. After that, we want to split the **training** data. \##
Initial split into training and testing groups

``` r
model_input_split = spatial_initial_split(model_input, 
                        prop = 1 / 5,     # 20% for testing
                        strategy = spatial_block_cv) # see ?spatial_block_cv
model_input_split
```

    ## <Training/Testing/Total>
    ## <703/54/757>

``` r
autoplot(model_input_split)
```

![](C04_assignment_files/figure-gfm/initial_split_plot-1.png)<!-- -->

## Split the training group into regional folds

Next we take just the **training** data and split that into a set
cross-validation folds and create mini/smaller data sets.

``` r
tr_data = training(model_input_split)
cv_tr_data <- spatial_block_cv(tr_data,
  v = 5,     
  cellsize = grid_cellsize(model_input),
  offset = grid_offset(model_input) + 0.00001
)
autoplot(cv_tr_data)
```

![](C04_assignment_files/figure-gfm/cv_training-1.png)<!-- --> \## Build
a recipe

Now, we make a recipe, which is a blueprint that guides the data
handling and modeling process.

``` r
one_row_of_training_data = dplyr::slice(tr_data,1)
rec = recipe(one_row_of_training_data, formula = class ~ .)
rec
```

    ## 

    ## ── Recipe ──────────────────────────────────────────────────────────────────────

    ## 

    ## ── Inputs

    ## Number of variables by role

    ## outcome:   1
    ## predictor: 9
    ## coords:    2

``` r
summary(rec)
```

    ## # A tibble: 12 × 4
    ##    variable type      role      source  
    ##    <chr>    <list>    <chr>     <chr>   
    ##  1 depth    <chr [2]> predictor original
    ##  2 month    <chr [2]> predictor original
    ##  3 SSS      <chr [2]> predictor original
    ##  4 U        <chr [2]> predictor original
    ##  5 Sbtm     <chr [2]> predictor original
    ##  6 V        <chr [2]> predictor original
    ##  7 Tbtm     <chr [2]> predictor original
    ##  8 MLD      <chr [2]> predictor original
    ##  9 SST      <chr [2]> predictor original
    ## 10 X        <chr [2]> coords    original
    ## 11 Y        <chr [2]> coords    original
    ## 12 class    <chr [3]> outcome   original

## Create a workflow

We make a workflow in order to put the data into containers for storing
the pre-processing steps and model specifications. we are using four
types of models.

``` r
wflow = workflow_set(
  
  preproc = list(default = rec), # not much happening in our preprocessor
  
  models = list(                 # but we have 4 models to add
    
      # very simple - nothing to tune
      glm = logistic_reg(
          mode = "classification") |>
        set_engine("glm"),
      
      # two knobs to tune
      rf = rand_forest(
          mtry = tune(),
          trees = tune(),
          mode = "classification") |>
        set_engine("ranger", 
                   importance = "impurity"),
      
      # so many things to tune!
      btree = boost_tree(
          mtry = tune(), 
          trees = tune(), 
          tree_depth = tune(), 
          learn_rate = tune(), 
          loss_reduction = tune(), 
          stop_iter = tune(),
          mode = "classification") |>
        set_engine("xgboost"),
    
      # just two again
      maxent = maxent(
          feature_classes = tune(),
          regularization_multiplier = tune(),
          mode = "classification") |>
        set_engine("maxnet")
  )
)
wflow
```

    ## # A workflow set/tibble: 4 × 4
    ##   wflow_id       info             option    result    
    ##   <chr>          <list>           <list>    <list>    
    ## 1 default_glm    <tibble [1 × 4]> <opts[0]> <list [0]>
    ## 2 default_rf     <tibble [1 × 4]> <opts[0]> <list [0]>
    ## 3 default_btree  <tibble [1 × 4]> <opts[0]> <list [0]>
    ## 4 default_maxent <tibble [1 × 4]> <opts[0]> <list [0]>

## Chosing metrics for measuring how well the models do

Now, we next chose which metrics to use when evaluating model
performance.

``` r
metrics = sdm_metric_set(yardstick::accuracy)
metrics
```

    ## A metric set, consisting of:
    ## - `boyce_cont()`, a probability metric | direction: maximize
    ## - `roc_auc()`, a probability metric    | direction: maximize
    ## - `tss_max()`, a probability metric    | direction: maximize
    ## - `accuracy()`, a class metric         | direction: maximize

## Fit the models to the various recipes

# Hyperparameters

These parameters help guide the optimal structure for solving the
problem and are set for each model. \### Iterate to find various
hyperparameter sets

we will use a function that will take each recipe-model combination and
iterator over each of the folds while adjusting the parameters . The
results of each iteration will be tracked so we can get a sense of the
range and average three times.

``` r
wflow <- wflow |>
  workflow_map("tune_grid",
    resamples = cv_tr_data, 
    grid = 3,
    metrics = metrics, 
    verbose = TRUE)
```

    ## i    No tuning parameters. `fit_resamples()` will be attempted

    ## i 1 of 4 resampling: default_glm

    ## ✔ 1 of 4 resampling: default_glm (706ms)

    ## i 2 of 4 tuning:     default_rf

    ## i Creating pre-processing data to finalize 1 unknown parameter: "mtry"

    ## ✔ 2 of 4 tuning:     default_rf (13.7s)

    ## i 3 of 4 tuning:     default_btree

    ## i Creating pre-processing data to finalize 1 unknown parameter: "mtry"

    ## → A | warning: `early_stop` was reduced to 0.

    ## There were issues with some computations   A: x1There were issues with some computations   A: x2There were issues with some computations   A: x3There were issues with some computations   A: x4There were issues with some computations   A: x5There were issues with some computations   A: x5
    ## ✔ 3 of 4 tuning:     default_btree (20.2s)
    ## i 4 of 4 tuning:     default_maxent
    ## ✔ 4 of 4 tuning:     default_maxent (2.7s)

Let’s plot it!

``` r
autoplot(wflow)
```

![](C04_assignment_files/figure-gfm/plot_wflow-1.png)<!-- --> \###
Choose the best set of hyperparameters for each model

``` r
model_fits = workflowset_selectomatic(wflow, model_input_split,
                                  filename = "Halichoerus_grypus-v1-model_fits",
                                  path = data_path("models"))
model_fits
```

    ## # A tibble: 4 × 7
    ##   wflow_id      splits           id    .metrics .notes   .predictions .workflow 
    ##   <chr>         <list>           <chr> <list>   <list>   <list>       <list>    
    ## 1 default_glm   <split [703/54]> trai… <tibble> <tibble> <tibble>     <workflow>
    ## 2 default_rf    <split [703/54]> trai… <tibble> <tibble> <tibble>     <workflow>
    ## 3 default_btree <split [703/54]> trai… <tibble> <tibble> <tibble>     <workflow>
    ## 4 default_maxe… <split [703/54]> trai… <tibble> <tibble> <tibble>     <workflow>

## Exploring the collection of model fit results

### A table of metrics

``` r
model_fit_metrics(model_fits)
```

    ## # A tibble: 4 × 5
    ##   wflow_id       accuracy boyce_cont roc_auc tss_max
    ##   <chr>             <dbl>      <dbl>   <dbl>   <dbl>
    ## 1 default_glm       0.815      0.767   0.805   0.645
    ## 2 default_rf        0.722      0.816   0.811   0.571
    ## 3 default_btree     0.741     -0.108   0.828   0.602
    ## 4 default_maxent    0.778      0.758   0.791   0.693

### Confusion matrices and accuracy

We can plot confusion matrices and add accuracy.

``` r
model_fit_confmat(model_fits)
```

![](C04_assignment_files/figure-gfm/model_fit_confmat-1.png)<!-- -->
\### ROC/AUC

``` r
model_fit_roc_auc(model_fits)
```

![](C04_assignment_files/figure-gfm/model_fit_roc_auc-1.png)<!-- -->
\### Variable importance

Variable importance tells us about the contribution each covariate
variable makes toward the whole within a certain model. NOTE: This is
still not working for me…

``` r
model_fit_varimp_plot(model_fits)
```

![](C04_assignment_files/figure-gfm/model_fit_vip-1.png)<!-- --> \##
Exploring a single model fit result

``` r
rf = model_fits |>
  filter(wflow_id == "default_rf")
rf
```

    ## # A tibble: 1 × 7
    ##   wflow_id   splits           id       .metrics .notes   .predictions .workflow 
    ##   <chr>      <list>           <chr>    <list>   <list>   <list>       <list>    
    ## 1 default_rf <split [703/54]> train/t… <tibble> <tibble> <tibble>     <workflow>

``` r
autoplot(rf$splits[[1]])
```

![](C04_assignment_files/figure-gfm/rf_splits-1.png)<!-- -->

``` r
rf$.metrics[[1]]
```

    ## # A tibble: 4 × 4
    ##   .metric    .estimator .estimate .config        
    ##   <chr>      <chr>          <dbl> <chr>          
    ## 1 accuracy   binary         0.722 pre0_mod0_post0
    ## 2 boyce_cont binary         0.816 pre0_mod0_post0
    ## 3 roc_auc    binary         0.811 pre0_mod0_post0
    ## 4 tss_max    binary         0.571 pre0_mod0_post0

``` r
rf$.predictions[[1]]
```

    ## # A tibble: 54 × 6
    ##    class      .pred_class .pred_presence .pred_background  .row .config        
    ##    <fct>      <fct>                <dbl>            <dbl> <int> <chr>          
    ##  1 background background          0.321             0.679     7 pre0_mod0_post0
    ##  2 background background          0.220             0.780    13 pre0_mod0_post0
    ##  3 background background          0.235             0.765    29 pre0_mod0_post0
    ##  4 background background          0.236             0.764    39 pre0_mod0_post0
    ##  5 presence   background          0.184             0.816    42 pre0_mod0_post0
    ##  6 background background          0.176             0.824    57 pre0_mod0_post0
    ##  7 background background          0.166             0.834    58 pre0_mod0_post0
    ##  8 background background          0.184             0.816    71 pre0_mod0_post0
    ##  9 background background          0.0784            0.922   116 pre0_mod0_post0
    ## 10 background background          0.0638            0.936   129 pre0_mod0_post0
    ## # ℹ 44 more rows

``` r
rf$.workflow[[1]]
```

    ## ══ Workflow [trained] ══════════════════════════════════════════════════════════
    ## Preprocessor: Recipe
    ## Model: rand_forest()
    ## 
    ## ── Preprocessor ────────────────────────────────────────────────────────────────
    ## 0 Recipe Steps
    ## 
    ## ── Model ───────────────────────────────────────────────────────────────────────
    ## Ranger result
    ## 
    ## Call:
    ##  ranger::ranger(x = maybe_data_frame(x), y = y, mtry = min_cols(~1L,      x), num.trees = ~2000L, importance = ~"impurity", num.threads = 1,      verbose = FALSE, seed = sample.int(10^5, 1), probability = TRUE) 
    ## 
    ## Type:                             Probability estimation 
    ## Number of trees:                  2000 
    ## Sample size:                      703 
    ## Number of independent variables:  9 
    ## Mtry:                             1 
    ## Target node size:                 10 
    ## Variable importance mode:         impurity 
    ## Splitrule:                        gini 
    ## OOB prediction error (Brier s.):  0.224573

### Partial dependence plot

This reflects the relative contribution of each variable influence over
it’s full range of values.

``` r
model_fit_pdp(model_fits, wid = "default_btree", title = "Boosted Tree")
```

![](C04_assignment_files/figure-gfm/pd_plot-1.png)<!-- -->
