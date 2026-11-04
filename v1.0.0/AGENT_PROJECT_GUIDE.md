# PicX Docker 容器化版本智能体指南 (Agent Project Guide)

本文件专为后续接手的智能体 (Agent) 与维护者编写，记录该版本（v1.0.0）的技术架构、容器化改造、已知问题与修复、运行与自测指引及后续迭代路线图。

---

## 1. 架构与模块功能 (Architecture & Modules)

- **上游基础**：基于开源项目 [XPoet/picx](https://github.com/XPoet/picx) (v3.2.1) 进行 Docker 容器化二次开发。
- **技术栈**：
  - 前端框架：Vue 3 + TypeScript + Pinia + Vue Router (Hash 模式)
  - 构建工具：Vite 8 + Rolldown/ESBuild + PWA
  - 核心计算库：`@jsquash/avif`、`@jsquash/jpeg`、`@jsquash/oxipng`、`@jsquash/webp` (基于 WebAssembly，所有图片编解码全部在浏览器本地完成)
  - 部署容器：Node 24 (多阶段编译构建) + Nginx Alpine (轻量静态服务与反向路由)
- **核心模块**：
  1. `图片工具箱`：本地压缩、格式转换、裁剪、水印、宫格切图、拼接、标记。
  2. `GitHub 图床`：浏览器直连 GitHub REST API 托管管理仓库图片，支持 Token 与 OAuth 模式。

---

## 2. 容器化适配修改点 (Modifications & Bug Fixes)

### 问题 1：原版路由 Base 路径硬编码
- **原因**：原版 `vite.config.ts` 中写死了 `base: '/images-hosting/'`，导致 Docker 托管在根路径时静态资源 404。
- **解决方案**：修改 `vite.config.ts` 中的 `base` 为 `env.VITE_BASE_URL || '/'`，默认支持根路径部署，同时支持通过环境变量自定义。
- **辅助保障**：在 `nginx.conf` 中追加了 `location /images-hosting/ { rewrite ^/images-hosting/(.*)$ /$1 last; }`，即使在子路径访问亦能平滑重写。

### 问题 2：容器构建时 Husky Git Hook 报错
- **原因**：Dockerfile 中执行 `pnpm install` 时，原项目的 `prepare: husky` 试图寻找 `.git` 目录，导致构建失败退出。
- **解决方案**：在 Dockerfile 构建阶段注入 `ENV HUSKY=0` 并使用 `pnpm install --frozen-lockfile --ignore-scripts`，跳过本地 Git 钩子触发。

### 问题 3：Pnpm v11+ Global Virtual Store 校验拦截
- **原因**：在 Dockerfile 阶段直接调用 `pnpm build` 时触发了 pnpm v11 的依赖运行时状态变更校验。
- **解决方案**：在 Docker 构建阶段直接调用 `./node_modules/.bin/vite build --configLoader runner`，跳过 pnpm 壳层校验，直接完成 Vite 生产打包。

### 问题 4：Wasm MIME 类型支持与静态资源缓存
- **原因**：PicX 严重依赖 `.wasm` WebAssembly 二进制模块进行图片编解码。
- **解决方案**：在 `nginx.conf` 中显式配置 `application/wasm` 压缩支持，并对 `.wasm`、`.js`、`.css` 启用长缓存，对 `index.html` 和 `sw.js` 禁用缓存避免更新不及时。

---

## 3. 运行与自测指引 (Run & Test Guide)

### 一键运行
- **Docker Compose**：
  ```bash
  docker compose up -d --build
  ```
  默认开放端口：`http://localhost:8088`（避免与常见 8080 冲突）。
- **脚本入口**：
  - Windows: 双击运行 `start-docker.bat`（纯 ASCII 编码，防止 GBK 乱码）。
  - Linux/macOS: `./start-docker.sh`。

### 自测验证命令
```bash
# 验证 HTTP 响应与 SPA 路由回退
curl -I http://localhost:8088/
curl -I http://localhost:8088/upload

# 验证 Wasm 文件内容类型正确
curl -I http://localhost:8088/assets/webp_dec-C990n7mh.wasm
# 预期返回: Content-Type: application/wasm, 200 OK
```

---

## 4. 资源消耗实测数据 (Performance Benchmark)

- **容器内存占用**：约 `5.7 MB`（Nginx Alpine 基础内存）。
- **容器 CPU 占用**：平时近乎 `0.00%`。
- **算力分配模型**：服务端仅负责静态资源分发，图片处理全部由客户端浏览器 CPU/Wasm 承担。

---

## 5. 待改进功能与路线图 (Roadmap & Future Work)

1. **多存储源支持扩展**：未来可探索在前端增加 S3、WebDAV 或 MinIO 图床驱动。
2. **多语言与自定义域名环境变量注入**：支持通过 Docker Compose 环境变量在运行时动态注入 GitHub OAuth ClientID 等配置。
