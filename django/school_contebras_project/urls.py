"""
URL configuration for school_contebras_project project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
# """

from django.contrib import admin
from django.urls import path, include
from django.contrib.auth import views as auth_views

urlpatterns = [
    path('', include('school_contebras_core_video.urls')),
    path('admin/', admin.site.urls),
    path('accounts/', include('django.contrib.auth.urls')),

    # ✅ Isso é ESSENCIAL para o Django Admin funcionar corretamente:
    path('login/', auth_views.LoginView.as_view(), name='login'),
]
# urlpatterns = [
#     path('', include('school_contebras_core_video.urls')),
#     path('admin/', admin.site.urls),
# ]
# from django.contrib import admin
# from django.urls import include, path
# from django.contrib.auth import views as auth_views  # <-- ESTA LINHA É ESSENCIAL
# from . import views

# urlpatterns = [
#     path('', views.home, name='home'),
#     # path('videos/', include('school_contebras_core_video.urls')),
#     path('accounts/login/', auth_views.LoginView.as_view(template_name='registration/login.html'), name='login'),
#     path('register/', views.register_user, name='register_user'),

#     path('admin/', admin.site.urls),
#     # path('api/', include('school_contebras_core_video.urls')),
#     path('api/videos/', include('school_contebras_core_video.urls'))



  
# ]
