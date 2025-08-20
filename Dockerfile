## Build Stage
# Stage 1: Install all dependencies including development dependencies
FROM node:20-alpine AS development-dependencies-env
COPY . /app
WORKDIR /app
RUN npm ci

# Stage 2: Install only production dependencies
FROM node:20-alpine AS production-dependencies-env
COPY ./package.json package-lock.json /app/
WORKDIR /app
RUN npm ci --omit=dev

# Stage 3: Build the application
FROM node:20-alpine AS build-env
COPY . /app/
# Copy node_modules from development environment (needed for building)
COPY --from=development-dependencies-env /app/node_modules /app/node_modules
WORKDIR /app
RUN npm run build

## Run Stage
# Stage 4: Create the final runtime image
FROM node:20-alpine
# Copy package files for runtime
COPY ./package.json package-lock.json /app/
# Copy only production dependencies (smaller image size)
COPY --from=production-dependencies-env /app/node_modules /app/node_modules
# Copy the built application
COPY --from=build-env /app/build /app/build
WORKDIR /app
CMD ["npm", "run", "start"]
