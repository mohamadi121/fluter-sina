FROM nginx:stable-alpine

# Copy the nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create app directory
RUN mkdir -p /usr/share/nginx/html

# Add a placeholder index.html file
RUN echo '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Asoud</title></head><body><h1>Asoud - Coming Soon</h1><p>Website is being prepared...</p></body></html>' > /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
