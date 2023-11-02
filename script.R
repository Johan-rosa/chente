
# Paquetes ----------------------------------------------------------------
library(dplyr)
library(tidyr)
library(purrr)
library(crosstalk)
library(plotly)
library(vembedr)
library(cat)
library(stringr)

# Setup -------------------------------------------------------------------
Sys.setlocale("LC_ALL", "de_DE.UTF-8")

make_interactive_plot <- function(shared_data) {
  shared_data |>
    plotly::plot_ly(x = ~ano, y = ~valor, color = ~desagragacion, legendgroup = ~desagragacion) |>
    plotly::add_trace(type = "scatter", mode = "markers+lines") |>
    layout(
      xaxis = list(title = "Año"), dragmode="orbit", clickmode="event+select",
      legend = list(
        orientation = "h",  
        xanchor = "center",
        x = 0.5,
        y=1.15
      ),
      shapes = list(
        type = "rect",
        text = 'COVID-19',
        fillcolor = "blue",
        line = list(color = "blue"),
        opacity = 0.2,
        yref ="paper",
        y0 = 0.08,
        y1 = 0.95,
        x0 = 2019.75,
        x1 = 2020.25)
    )
}

create_plot_widget <- function(data, categoria, selected_scope = "general") {
  data_to_plot <- dplyr::filter(
    data,
    scope == selected_scope,
    grupo_indicador == categoria
  )
  
  shared_data <- crosstalk::SharedData$new(
    data_to_plot,
    key = ~key,
    group = categoria
  )
  
  plot  <- make_interactive_plot(shared_data)
  
  htmltools::div(
    crosstalk::filter_select(
      id = categoria,
      label = "Selecionar indicador",
      sharedData = shared_data,
      group = ~indicador,
      allLevels = FALSE,
      multiple = FALSE
    ),
    plot
  )
  
}

# Data --------------------------------------------------------------------

desagregacion_seleccionada <- c("Población sin categoría", "Familiar no remunerado", "Patrono o socio activo")

general <- readxl::read_excel("desempleo_Joven_adultosb (1).xlsx", sheet = "General") |>
  tidyr::pivot_longer(
    cols = -c(Ano, Desagragacion),
    names_to = "Indicador",
    values_to = "Valor"
  ) |>
  filter(
    !Desagragacion %in% desagregacion_seleccionada,
    Ano %in% c(2015:2022)
  ) |>
  tibble::rowid_to_column(var = "key") |> 
  janitor::clean_names()

joven <- Joven <- readxl::read_excel("desempleo_Joven_adultosb (1).xlsx", sheet = "Joven") |>
  tidyr::pivot_longer(
    cols = -c(Ano, Desagragacion, Descripcion),
    names_to = "Indicador",
    values_to = "Valor"
  ) |>
  filter(
    !Desagragacion %in% desagregacion_seleccionada,
    Ano %in% c(2015:2022)
  ) |>
  tibble::rowid_to_column(var = "key") |>
  janitor::clean_names()

full_data <- bind_rows(general = general, joven = joven, .id = "scope") |>
  mutate(
    grupo_indicador = case_when(
      str_detect(indicador, " ocupa") ~ "ocupacion",
      str_detect(indicador, "desocupa") ~ "desocupacion",
      str_detect(indicador, "informal") ~ "informalidad",
      str_detect(indicador, "inactiv") ~ "inactividad",
      str_detect(indicador, "participaci|económica") ~ "participacion",
      str_detect(indicador, "subocupa") ~ "subocupacion",
      str_detect(indicador, "Salario") ~ "salario"
    )
  )

# Gráficos ----------------------------------------------------------------



ocupacion_general_data <- general |> 
  dplyr::filter(indicador %in% c("Tasa de ocupación" ,  "Cantidad de ocupados" ))

ocupacion_general_shared <- SharedData$new(ocupacion_general_data, key = ~key , group = "ocupadosg")
ocupacion_general_plot   <- make_interactive_plot(ocupacion_general_shared)


ocupacion_joven_data <- joven |> 
  filter(indicador %in% c("Tasa de ocupación" ,  "Cantidad de ocupados"))

ocupacion_joven_shared <- SharedData$new(ocupacion_joven_data, key = ~key,  group = "ocupadosj") 
ocupacion_joven_plot   <- make_interactive_plot(ocupacion_joven_shared)







