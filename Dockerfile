FROM python:3.11-slim

# Базовые зависимости + zsh и инструменты для комфортного шелла
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        zsh git curl ca-certificates locales fzf nano procps passwd sudo \
    && rm -rf /var/lib/apt/lists/*

# Установим jupyterlab и полезные расширения (включая коллаборацию)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gcc python3-dev build-essential; \
    pip install --upgrade pip; \
    pip install --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org \
      jupyterlab jupyter-collaboration \
      jupyterlab-git jupyterlab-lsp python-lsp-server \
      jupyterlab-code-formatter black isort \
      ipywidgets \
      jupyter-ai[anthropic,openai] gpt4all langchain-openai langchain-community \
      lckr-jupyterlab-variableinspector; \
    jupyter server extension enable --py jupyterlab_code_formatter --sys-prefix; \
    jupyter server extension enable --py jupyterlab_git --sys-prefix; \
    apt-get purge -y --auto-remove gcc python3-dev build-essential; \
    rm -rf /var/lib/apt/lists/*

# Создадим юзера, чтобы не работать от root, и сделаем zsh шеллом по умолчанию
RUN useradd -ms /bin/zsh jovyan
RUN echo "jovyan:123456" | chpasswd && adduser jovyan sudo

USER jovyan
WORKDIR /home/jovyan

# Установка Oh My Zsh и популярных плагинов/темы
ENV ZSH=/home/jovyan/.oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH/custom/themes/powerlevel10k \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $ZSH/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $ZSH/custom/plugins/zsh-syntax-highlighting \
    && sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc \
    && sed -i 's|^plugins=.*|plugins=(git fzf z python pip docker history-substring-search zsh-autosuggestions zsh-syntax-highlighting)|' ~/.zshrc \
    && echo "\n# p10k instant prompt\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> ~/.zshrc

# Настройка zsh как дефолтного шелла для Jupyter
RUN mkdir -p ~/.jupyter \
    && echo "c.ServerApp.terminado_settings = {'shell_command': ['/bin/zsh']}" > ~/.jupyter/jupyter_server_config.py

# Откроем порт
EXPOSE 8888

COPY .zshrc .p10k.zsh /home/jovyan/

RUN git clone https://github.com/darkydash/ml_hse_2024.git /home/jovyan/ml_hse

ENV OPENAI_API_BASE=https://api.poe.com/v1
ENV OPENAI_API_KEY=

# Запуск JupyterLab без токена/пароля
CMD ["jupyter", "lab", "--collaborative", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--ServerApp.allow_origin=http://jupyter.sleep3r.ru", "--NotebookApp.token=", "--NotebookApp.password="]