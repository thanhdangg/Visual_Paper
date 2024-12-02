import requests
from bs4 import BeautifulSoup
import csv

# Crawl danh sách bài viết từ chuyên mục
def get_article_links(base_url):
    response = requests.get(base_url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Lấy link các bài viết
    article_links = [a['href'] for a in soup.select('.title-news a') if 'href' in a.attrs]
    return article_links

# Crawl nội dung bài viết
def get_article_content(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Tiêu đề bài viết
    title = soup.select_one('h1.title-detail').text.strip() if soup.select_one('h1.title-detail') else "Không tiêu đề"
    
    description = soup.select_one('p.description').text.strip() if soup.select_one('p.description') else "Không có mô tả" 
    # Nội dung bài viết
    content = ' '.join([p.text.strip() for p in soup.select('article.fck_detail p')])
    print("Title: ", title)
    print("Description: ", description)
    print("Content: ", content)
    return title, description,  content

# URL chuyên mục
base_url = "https://vnexpress.net/khoa-hoc/khoa-hoc-trong-nuoc"
article_links = get_article_links(base_url)


# Crawl nội dung các bài viết
articles = []
for link in article_links:  # Crawl 10 bài viết đầu tiên
    try:
        title, description,  content = get_article_content(link)
        articles.append({"title": title, "description": description,"url": link, "content": content})
        print(f"Crawled: {title}")
    except Exception as e:
        print(f"Error: {e}")

print(f"Crawled {len(articles)} articles.")

# output_file = "vnexpress_technology.csv"
output_file = "vnexpress_science_internal.csv"

with open(output_file, mode='w', encoding='utf-8', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=["title", "url", "description", "content"])
    writer.writeheader()
    writer.writerows(articles)

print(f"Đã lưu {len(articles)} bài viết vào tệp {output_file}.")
