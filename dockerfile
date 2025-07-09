# Stage 1: Build the application with dev dependencies
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

# Install development dependencies, as Jest (a dev dependency) is used for testing
RUN npm ci

# Copy the rest of the application code
COPY . .

# Run tests, linting, and security audit
RUN npm test
RUN npm run lint
# RUN npm run security:audit # Uncomment if you want security audit to fail the build

# Stage 2: Create the production-ready slim image
FROM node:18-alpine AS production

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json to the production image
# This is crucial for 'npm start' to find the project's scripts
COPY package*.json ./

# Copy only production dependencies from the builder stage
# This keeps the final image small by excluding dev dependencies
COPY --from=builder /app/node_modules ./node_modules

# Copy only the necessary application files for production
COPY server.js ./
COPY public ./public
# If you have other directories like 'routes', 'controllers', 'models', copy them too
# COPY src ./src
# COPY config ./config

# Expose the port your application runs on (typically 3000 for Node.js Express apps)
EXPOSE 3000

# Command to run the application
CMD ["npm", "start"]
