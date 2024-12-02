# Tải các thư viện cần thiết
library(shiny)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(dplyr)
library(readr)

# Danh sách stopwords tiếng Việt (mở rộng theo yêu cầu)
vietnamese_stopwords <- c(
  "và", "của", "theo", "để", "trong", "là", "với", "có", "là",
  "này", "đã", "chúng", "một", "các", "trên", "sẽ", "như", "vào",
  "lúc", "được", "bằng", "khi", "nhiều", "còn", "vì", "cũng", "điều",
  "sử", "dụng", "không", "là", "nên", "thì", "đến", "vẫn", "hoặc"
)

# Đọc dữ liệu từ file CSV
data <- read_csv("vnexpress_technology.csv")

# Làm sạch và kết hợp các cột title, description, content thành một văn bản
clean_data <- data %>%
  filter(!is.na(title) & !is.na(description) & !is.na(content)) %>%
  filter(title != "" & description != "" & content != "") # Lọc bỏ dòng trống

# Kết hợp các cột thành một văn bản duy nhất
text_data <- paste(clean_data$title, clean_data$description, clean_data$content, collapse = " ")

# Hàm xử lý văn bản
getTermMatrix <- function(text) {
  # Tạo corpus
  myCorpus <- Corpus(VectorSource(text))

  # Xử lý văn bản: chuyển sang chữ thường, loại bỏ dấu câu, số, từ dừng
  myCorpus <- tm_map(myCorpus, content_transformer(tolower)) # Chuyển sang chữ thường
  myCorpus <- tm_map(myCorpus, removePunctuation) # Loại bỏ dấu câu
  myCorpus <- tm_map(myCorpus, removeNumbers) # Loại bỏ số

  # Loại bỏ các từ stopwords tiếng Việt
  myCorpus <- tm_map(myCorpus, removeWords, vietnamese_stopwords) # Loại bỏ stopwords tiếng Việt

  # Kiểm tra dữ liệu trong corpus
  if (length(myCorpus) > 0) {
    # Tạo ma trận tần suất từ
    tdm <- TermDocumentMatrix(myCorpus)
    m <- as.matrix(tdm)
    v <- rowSums(m)
    v <- sort(v, decreasing = TRUE)
    return(v)
  } else {
    return(NULL) # Trả về NULL nếu không có dữ liệu hợp lệ
  }
}

# Ứng dụng Shiny
ui <- fluidPage(
  titlePanel("Word Cloud từ dữ liệu VNExpress"),
  sidebarLayout(
    sidebarPanel(
      # Đặt tệp csv trong thư mục làm việc
      fileInput("file", "Chọn tệp CSV", accept = c(".csv"))
    ),
    mainPanel(
      plotOutput("wordCloudPlot") # Hiển thị word cloud
    )
  )
)

server <- function(input, output) {
  # Xử lý tệp được tải lên
  observeEvent(input$file, {
    # Đọc dữ liệu từ tệp CSV
    data <- read_csv(input$file$datapath)

    # Làm sạch dữ liệu
    clean_data <- data %>%
      filter(!is.na(title) & !is.na(description) & !is.na(content)) %>%
      filter(title != "" & description != "" & content != "")

    # Kết hợp các cột title, description, content thành một văn bản
    text_data <- paste(clean_data$title, clean_data$description, clean_data$content, collapse = " ")

    # Xử lý và tạo Word Cloud
    term_freq <- getTermMatrix(text_data)

    output$wordCloudPlot <- renderPlot({
      # Nếu có dữ liệu hợp lệ, tạo word cloud
      if (!is.null(term_freq)) {
        wordcloud(names(term_freq), term_freq, scale = c(3, 0.5), colors = brewer.pal(8, "Dark2"))
      } else {
        plot.new()
        text(0.5, 0.5, "Không có dữ liệu để tạo Word Cloud", cex = 1.5)
      }
    })
  })
}

# Chạy ứng dụng Shiny
shinyApp(ui = ui, server = server)
