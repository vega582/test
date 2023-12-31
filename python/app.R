library(reticulate)
library(teal)
library(teal.modules.general)
library(nestcolor)
# optional libraries
library(colourpicker)
library(ggExtra)
library(ggpmisc)
library(sparkline)

options(shiny.useragg = FALSE)

python_dependencies <- c("pip", "numpy", "pandas")
virtualenv_dir <- Sys.getenv("VIRTUALENV_NAME")
python_path <- Sys.getenv("PYTHON_PATH")

print("################################ Logging ################################")
print(Sys.getenv("PYTHON_PATH"))
print(Sys.getenv("VIRTUALENV_NAME"))
print(Sys.getenv("RETICULATE_PYTHON"))
print(Sys.info()[["user"]])
print(virtualenv_dir)
print(python_path)
print("################################ Logging ################################")

reticulate::virtualenv_create(envname = virtualenv_dir, python = python_path)
reticulate::virtualenv_install(virtualenv_dir, packages = python_dependencies, ignore_installed = TRUE)
reticulate::use_virtualenv(virtualenv_dir, required = TRUE)

iris_raw <- cbind(id = 1:nrow(iris), iris)

python_code <- "import pandas as pd
data = r.data_raw
def svd_whiten(dat):
  import numpy as np
  X = np.matrix(dat)
  U, s, Vt = np.linalg.svd(X, full_matrices=False)
  X_white = np.dot(U, Vt)
  return X_white
data_columns = data.columns
global numeric_cols_ix
global numeric_cols
numeric_cols_ix = list(range(5))[1:]
numeric_cols = [x for i,x in enumerate(data_columns) if i in numeric_cols_ix]
svd_res = svd_whiten(data.iloc[:, numeric_cols_ix])
data_new = pd.concat([data, pd.DataFrame(svd_res)], axis = 1)
data_new.columns = list(data_columns) + [i + '.whiten' for i in numeric_cols]
data_new = data_new.round(10)
data_new
"

app <- teal::init(
  data = teal_data(python_dataset_connector(
    "IRIS",
    code = python_code,
    object = "data_new",
    keys = "id",
    vars = list(data_raw = iris_raw)
  )) %>% mutate_data("IRIS$id <- as.integer(IRIS$id)"),
  title = "Example teal app using python connector",
  modules = modules(
    tm_data_table("Data Table"),
    tm_variable_browser("Variable Browser"),
    tm_g_scatterplot(
      "Scatterplot",
      x = data_extract_spec(
        dataname = "IRIS",
        select = select_spec(
          label = "Select variable:",
          choices = variable_choices("IRIS", c(
            "Sepal.Length", "Sepal.Width",
            "Petal.Length", "Petal.Width",
            "Sepal.Length.whiten", "Sepal.Width.whiten",
            "Petal.Length.whiten", "Petal.Width.whiten"
          )),
          selected = "Petal.Length.whiten",
          multiple = FALSE,
          fixed = FALSE
        )
      ),
      y = data_extract_spec(
        dataname = "IRIS",
        select = select_spec(
          label = "Select variable:",
          choices = variable_choices("IRIS", c(
            "Sepal.Length", "Sepal.Width",
            "Petal.Length", "Petal.Width",
            "Sepal.Length.whiten", "Sepal.Width.whiten",
            "Petal.Length.whiten", "Petal.Width.whiten"
          )),
          selected = "Petal.Width.whiten",
          multiple = FALSE,
          fixed = FALSE
        )
      ),
      color_by = data_extract_spec(
        dataname = "IRIS",
        select = select_spec(
          label = "Select variable:",
          choices = variable_choices("IRIS", c("Species")),
          selected = "Species",
          multiple = FALSE,
          fixed = FALSE
        )
      )
    )
  ),
  header = tags$span(
    style = "display: flex; align-items: center; justify-content: space-between; margin: 10px 0 10px 0;",
    tags$span(
      style = "font-size: 30px;",
      "Example teal app using python dataset connector"
    ),
    tags$span(
      style = "display: flex; align-items: center;",
      tags$img(src = "nest.png", alt = "NEST logo", height = "45px"),
      tags$span(style = "font-size: 24px;", "NEST @ Roche")
    )
  ),
  footer = tags$p(
    actionLink("showAboutModal", "About,"),
    tags$a(
      href = "https://github.com/insightsengineering/teal.gallery/tree/main/python",
      target = "_blank",
      "Source Code,"
    ),
    tags$a(
      href = "https://github.com/insightsengineering/teal.gallery/issues",
      target = "_blank",
      "Report Issues"
    )
  )
)

body(app$server)[[length(body(app$server)) + 1]] <- quote(
  observeEvent(input$showAboutModal, {
    showModal(modalDialog(
      tags$p("This teal app is brought to you by the NEST Team at Roche/Genentech. For more information, please visit:"),
      tags$ul(
        tags$li(tags$a(
          href = "https://github.com/insightsengineering", "Insights Engineering",
          target = "blank"
        )),
        tags$li(tags$a(
          href = "https://pharmaverse.org", "Pharmaverse",
          target = "blank"
        ))
      ),
      easyClose = TRUE
    ))
  })
)

shinyApp(app$ui, app$server)
