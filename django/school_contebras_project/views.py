from django.shortcuts import render, redirect
from django.contrib.auth.models import User
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth import login
from .forms import CustomUserCreationForm, SuperUserCreationForm

def home(request):
    return render(request, 'home.html')  # caminho relativo à pasta 'templates'

def login_view(request):
    form = AuthenticationForm(request, data=request.POST or None)

    if request.method == 'POST' and form.is_valid():
        user = form.get_user()
        login(request, user)
        return redirect('/')  # Altere para a página que desejar após login

    return render(request, 'login.html', {'form': form})

def register_user(request):
    if request.method == "POST":
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect("/")  # ou redirecione para o dashboard
    else:
        form = CustomUserCreationForm()
    return render(request, "register_user.html", {"form": form})

def register_superuser(request):
    if request.method == "POST":
        form = SuperUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save(commit=False)
            user.is_staff = True
            user.is_superuser = True
            user.save()
            login(request, user)
            return redirect("/admin/")
    else:
        form = SuperUserCreationForm()
    return render(request, "register_superuser.html", {"form": form})