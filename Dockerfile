FROM ghcr.io/cirruslabs/flutter:3.44.0@sha256:46691e311715845de03a3ba4753a475476936805b29431b1f00f1816981033f8 AS builder

ARG API_BASE_URL=http://localhost:8080/api/v1/
ARG PUB_HOSTED_URL=https://pub.dev
ARG FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com

WORKDIR /src

COPY pubspec.yaml pubspec.lock ./
RUN PUB_HOSTED_URL="$PUB_HOSTED_URL" \
    FLUTTER_STORAGE_BASE_URL="$FLUTTER_STORAGE_BASE_URL" \
    flutter pub get

COPY analysis_options.yaml ./
COPY assets/ ./assets/
COPY lib/ ./lib/
COPY web/ ./web/

RUN test -n "$API_BASE_URL" \
    && PUB_HOSTED_URL="$PUB_HOSTED_URL" \
       FLUTTER_STORAGE_BASE_URL="$FLUTTER_STORAGE_BASE_URL" \
       flutter build web --release \
        --dart-define=API_BASE_URL="$API_BASE_URL"


FROM nginx:stable-alpine@sha256:0d3b80406a13a767339fbe2f41406d6c7da727ab89cf8fae399e81f780f814d1 AS runtime

RUN apk del --no-cache nginx-module-image-filter curl

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /src/build/web/ /usr/share/nginx/html/

EXPOSE 80
