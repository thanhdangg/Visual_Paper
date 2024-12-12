library(shiny)
library(rvest)
library(dplyr)
library(wordcloud)
library(tm)

# stop words trong Tiếng Việt
stopwords_vi <- c(
  "và", "là", "của", "có", "cho", "để", "với", "như", "một", 
  "này", "nên", "ra", "vào", "lại", "lên", "xuống", "đó", 
  "đây", "kia", "đã", "đang", "sẽ", "cũng", "thì", "ở", "khi",
  "được", "bị", "do", "nếu", "hoặc", "vậy", "vì", "sao", "rất",
  "những", "các", "tại", "hơn", "không", "trong", "từ"
)

crawl_vnexpress <- function() {
  base_url <- "https://vnexpress.net/so-hoa/cong-nghe"
  response <- read_html(base_url)
  
  articles <- response %>%
    html_nodes(".title-news a") %>%
    html_attr("href") %>%
    unique()
  
  data <- lapply(articles, function(link) {
    page <- tryCatch(read_html(link), error = function(e) NULL)
    if (is.null(page)) return(NULL)
    
    title <- page %>% html_node(".title-detail") %>% html_text(trim = TRUE)
    description <- page %>% html_node(".description") %>% html_text(trim = TRUE)
    content <- page %>%
      html_nodes(".fck_detail p") %>%
      html_text(trim = TRUE) %>%
      paste(collapse = " ")
    
    data.frame(Title = title, URL = link, Description = description, Content = content, stringsAsFactors = FALSE)
  })
  
  do.call(rbind, data)
}

ui <- fluidPage(
  titlePanel("Crawl dữ liệu VnExpress: Số hóa - Công nghệ"),
  
  sidebarLayout(
    sidebarPanel(
      dateInput("date", "Chọn ngày:", value = Sys.Date(), format = "yyyy-mm-dd"),
      selectInput("data_type", "Chọn loại dữ liệu:", 
                  choices = c("Title" = "title", 
                              "Description" = "description", 
                              "Content" = "content")),
      actionButton("process", "Xử lý dữ liệu"),
      downloadButton("download_csv", "Tải xuống CSV")
    ),
    
    mainPanel(
      plotOutput("wordcloud"),
      textOutput("message")
    )
  )
)

server <- function(input, output, session) {
  csv_folder <- "data/" 
  
  observeEvent(input$process, {
    selected_date <- input$date
    today <- Sys.Date()
    
    if (selected_date > today) {
      output$message <- renderText("Ngày bạn chọn là ngày trong tương lai, hiện tại chưa có dữ liệu. Vui lòng chọn ngày khác.")
      output$wordcloud <- renderPlot({ NULL })
      return()
    }
    
    csv_file <- paste0(csv_folder, "vnexpress_data_", selected_date, ".csv")
    if (file.exists(csv_file)) {
      data <- read.csv(csv_file, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
      output$message <- renderText(paste("Dữ liệu wordcloud của ngày:", selected_date))
    } else if (selected_date == today) {
      data <- crawl_vnexpress()
      if (!is.null(data) && nrow(data) > 0) {
        write.csv(data, csv_file, row.names = FALSE, fileEncoding = "UTF-8")
        output$message <- renderText("Dữ liệu ngày hiện tại đã được crawl và lưu.")
      } else {
        output$message <- renderText("Không thể crawl dữ liệu cho ngày hiện tại.")
        output$wordcloud <- renderPlot({ NULL })
        return()
      }
    } else {
      output$message <- renderText("Không tìm thấy dữ liệu cho ngày được chọn.")
      output$wordcloud <- renderPlot({ NULL })
      return()
    }
    
    output$wordcloud <- renderPlot({
      req(input$data_type)
      text <- paste(data[[input$data_type]], collapse = " ")
      if (nchar(text) == 0) {
        plot.new()
        text(0.5, 0.5, "Không có dữ liệu để tạo Word Cloud", cex = 1.5)
        return()
      }
      
      corpus <- Corpus(VectorSource(text))
      corpus <- tm_map(corpus, content_transformer(tolower))
      corpus <- tm_map(corpus, removePunctuation)
      corpus <- tm_map(corpus, removeNumbers)
      corpus <- tm_map(corpus, removeWords, c(stopwords("en"), stopwords_vi))
      
      wordcloud(words = corpus, max.words = 100, random.order = FALSE, colors = brewer.pal(8, "Dark2"))
    })
  })
  
  output$download_csv <- downloadHandler(
    filename = function() {
      paste("vnexpress_data_", input$date, ".csv", sep = "")
    },
    content = function(file) {
      selected_date <- input$date
      csv_file <- paste0(csv_folder, "vnexpress_data_", selected_date, ".csv")
      if (file.exists(csv_file)) {
        file.copy(csv_file, file)
      } else {
        stop("Không có file CSV để tải xuống.")
      }
    }
  )
}

shinyApp(ui = ui, server = server)
