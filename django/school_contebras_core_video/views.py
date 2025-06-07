from django.shortcuts import render

def home(request):
    return render(request, 'home.html')  # caminho relativo à pasta 'templates'
