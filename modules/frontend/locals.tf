locals {
  s3_origin_id = "S3Origin-${terraform.workspace}"
  mime_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "svg"  = "image/svg+xml"
    "txt"  = "text/plain"
    "map"  = "application/json"
    "ico"  = "image/x-icon"
  }
}
