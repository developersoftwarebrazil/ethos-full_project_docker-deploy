#!/bin/bash

set -e

# =======================
# 🔧 Configurações iniciais
# =======================
DEFAULT_VOLUME_NAME="external-storage"
VOLUME_NAME="$DEFAULT_VOLUME_NAME"

# =======================
# 📦 Verificação/Criação de volume Docker externo (interativo)
# =======================
check_or_create_external_volume() {
    local volume_name=$1

    echo "🗃️ Verificando volume externo Docker '$volume_name'..."
    if docker volume inspect "$volume_name" >/dev/null 2>&1; then
        echo "✅ Volume externo '$volume_name' já existe."
    else
        echo "⚠️ Volume '$volume_name' não encontrado."
        read -p "🔤 Digite um nome para o novo volume Docker (ou pressione Enter para usar '$volume_name'): " new_volume_name
        volume_name="${new_volume_name:-$volume_name}"
        echo "📦 Criando volume externo '$volume_name'..."
        docker volume create --name "$volume_name"
        echo "✅ Volume externo '$volume_name' criado com sucesso!"
    fi

    export VOLUME_NAME="$volume_name"
}

check_or_create_external_volume "$VOLUME_NAME"

# =======================
# ⚙️ Funções utilitárias
# =======================
run_or_fail() {
    echo "⚙️ Executando: $1"
    eval "$1" || { echo "❌ Erro ao executar: $1"; exit 1; }
}

wait_for_container() {
    local container=$1
    echo "⏳ Aguardando container '$container' estar pronto..."
    while true; do
        if docker compose exec -T "$container" echo "✅ $container pronto" &>/dev/null; then
            echo "✅ Container '$container' está pronto!"
            return 0
        fi
        sleep 3
    done
}

kill_port() {
    local port=$1
    echo "🔧 Tentando liberar porta $port (se necessário)..."
    lsof -ti tcp:$port | xargs -r kill -9 || true
    fuser -k ${port}/tcp || true
}

# =======================
# 🚀 Execução principal
# =======================
echo "🔪 Finalizando processos que podem estar usando as portas necessárias..."
kill_port 8000
kill_port 3000
kill_port 3001
kill_port 3002

echo "🔧 Parando containers existentes..."

docker compose down -v --remove-orphans
docker system prune -a --volumes -f

echo "🔧 Limpando imagens antigas..."
docker image prune -f || true

echo "🔧 Subindo containers..."
docker compose up -d --build

wait_for_container django

echo "📦 Instalando dependências do Django..."
docker compose exec -T django bash -c "
command -v pipenv >/dev/null 2>&1 || (echo '⚙️ Instalando pipenv...' && pip install pipenv)
pipenv install
"

echo "🔎 Verificando migrações pendentes..."
MIGRATIONS_PENDING=$(docker compose exec -T django bash -c 'pipenv run python manage.py showmigrations | grep "\[ \]"' | wc -l)

if [ "$MIGRATIONS_PENDING" -gt 0 ]; then
    echo "⚒️ Migrações pendentes detectadas, aplicando..."
    run_or_fail "docker compose exec -T django bash -c 'pipenv run python manage.py migrate'"
else
    echo "✅ Nenhuma migração pendente"
fi

echo "👤 Garantindo superusuário Django..."
docker compose exec -T django bash -c "
pipenv run python manage.py shell -c \"
from django.contrib.auth import get_user_model;
User = get_user_model();
if not User.objects.filter(email='admin@user.com').exists():
    User.objects.create_superuser('admin1', 'admin@user.com', 'secret')
\""

echo "📦 Iniciando o django admin."
docker compose exec -T django bash -c "pipenv run python manage.py runserver 0.0.0.0:8000"

wait_for_container go_app_dev
wait_for_container nextjs

echo "📦 Iniciando o nextjs..."
docker compose exec -T nextjs bash -c "npm run dev"

echo "🎬 Iniciando consumidor Django - Upload Chunks (em background)..."
docker compose exec -T django bash -c "pipenv run python manage.py consumer_upload_chunks_to_external_storage" &

echo "📡 Iniciando consumidor Django - Registro Processamento (em background)..."
docker compose exec -T django bash -c "pipenv run python manage.py consumer_register_processed_video_path" &

sleep 5

echo ""
echo "✅ Ambiente pronto! Logs a seguir:"
echo ""
./
docker compose logs -f django django_consumer_register_processed django_consumer_upload_chunks go_app_dev nextjs postgres rabbitmq pgadmin
