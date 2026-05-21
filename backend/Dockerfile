# Sử dụng node 20 làm base
FROM node:20-slim AS builder

RUN apt-get update -y && apt-get install -y openssl

WORKDIR /app

# Sao chép file package.json và cài đặt dependencies
COPY package*.json ./
RUN npm ci

# Sao chép mã nguồn và schema prisma
COPY prisma ./prisma/
COPY tsconfig.json ./
COPY src ./src/

# Tạo Prisma Client và build TypeScript
RUN npx prisma generate
RUN npm run build

# Giai đoạn run
FROM node:20-slim

RUN apt-get update -y && apt-get install -y openssl

WORKDIR /app

# Chỉ sao chép các files cần thiết để chạy từ phase build
COPY package*.json ./
RUN npm ci --only=production

COPY prisma ./prisma/
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/@prisma/client ./node_modules/@prisma/client

# Tạo thư mục lưu file upload
RUN mkdir -p uploads

# Expose port
EXPOSE 3000

# Khởi chạy server và sinh DB migrate trước khi start
CMD ["sh", "-c", "npx prisma db push && node dist/app.js"]
