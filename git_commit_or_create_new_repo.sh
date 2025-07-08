  #!/bin/bash

  echo "📁 Diretório atual: $(basename "$(pwd)")"

  # Verifica se é repositório Git
  if [ ! -d .git ]; then
    echo "🚫 Este diretório não é um repositório Git. Deseja inicializar? (s/n)"
    read -r INIT
    if [[ "$INIT" =~ ^[sS]$ ]]; then
      git init
    else
      echo "❌ Encerrando script."
      exit 1
    fi
  fi

  # Exibe repositório remoto atual
  CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null)
  if [ -n "$CURRENT_REMOTE" ]; then
    echo "🔗 Repositório remoto atual: $CURRENT_REMOTE"
  else
    echo "⚠️ Nenhum repositório remoto configurado."
  fi

  # Commit de alterações locais
  echo ""
  read -p "📦 Deseja adicionar e commitar as alterações locais? (s/n): " DO_COMMIT
  if [[ "$DO_COMMIT" =~ ^[sS]$ ]]; then
    git add .
    read -p "📝 Mensagem do commit: " COMMIT_MSG
    git commit -m "$COMMIT_MSG" || echo "⚠️ Nenhuma alteração nova para commitar."
  fi

  # Trocar ou manter repositório remoto
  echo ""
  read -p "❓ Deseja criar um novo repositório remoto e substituir o atual? (s/n): " CHANGE_REMOTE
  if [[ "$CHANGE_REMOTE" =~ ^[sS]$ ]]; then
    # Coleta dados do usuário
    read -p "👤 GitHub username: " GITHUB_USERNAME
    read -s -p "🔑 GitHub Personal Access Token (não será exibido): " GITHUB_TOKEN
    echo ""
    read -p "📦 Nome do novo repositório no GitHub: " REPO_NAME
    read -p "🌐 Visibilidade (public/private): " REPO_VISIBILITY

    # Cria repositório no GitHub
    echo "🚧 Criando repositório '$REPO_NAME' no GitHub..."

    CREATE_REPO_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"$REPO_NAME\", \"private\":$( [[ "$REPO_VISIBILITY" == "private" ]] && echo true || echo false )}" \
      https://api.github.com/user/repos)

    if [[ "$CREATE_REPO_RESPONSE" != "201" ]]; then
      echo "❌ Falha ao criar repositório. Código HTTP: $CREATE_REPO_RESPONSE"
      exit 1
    fi

    # Remove remote antigo e adiciona novo
    git remote remove origin 2>/dev/null
    REMOTE_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    git remote add origin "$REMOTE_URL"

    echo "✅ Novo repositório criado e vinculado: $REMOTE_URL"
  fi

  # Garante branch "main"
  git branch -M main

  # Push para repositório remoto atual
  echo "🚀 Enviando alterações para o GitHub..."
  git push -u origin main

  echo "✅ Pronto! Tudo foi enviado para: $(git remote get-url origin)"

