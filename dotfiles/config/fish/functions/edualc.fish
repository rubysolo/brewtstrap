function edualc --description 'Local Claude'
  vllm-mlx serve \
    mlx-community/Qwen3.6-Coder-27B-Instruct-8bit \
    --port 8000
  export ANTHROPIC_BASE_URL=http://localhost:8000
  export ANTHROPIC_API_KEY=not-needed
  claude
end
