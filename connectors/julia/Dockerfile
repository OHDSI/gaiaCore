FROM julia:1.10

WORKDIR /app

# Copy project files
COPY Project.toml .
COPY GaiaCoreClient.jl .
COPY example.jl .
COPY pipeline_example.jl .

# Install dependencies
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'

CMD ["julia", "--project=.", "example.jl"]
