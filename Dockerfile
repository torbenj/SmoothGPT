# syntax=docker/dockerfile:1.4
FROM node:22.7-alpine AS build
WORKDIR /src
COPY package*.json .
RUN npm i
COPY . .
RUN npm run build

FROM nginx:1.27.1-alpine
WORKDIR /usr/share/nginx/html
COPY --link --from=build /src/dist/ .