FROM php:8.2-apache

# Instalar extensiones necesarias de MySQL PDO
RUN docker-php-ext-install pdo pdo_mysql

# Habilitar módulos de Apache
RUN a2enmod rewrite headers

# Directorio de trabajo
WORKDIR /var/www/html

# Copiar archivos del backend
COPY . /var/www/html/

# Crear carpeta de subidas para portafolio y otorgar permisos
RUN mkdir -p /var/www/html/uploads/portafolio && \
    chmod -R 777 /var/www/html/uploads

# Configurar Apache para escuchar dinámicamente en el puerto asignado por Railway ($PORT)
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

ENV PORT=80
EXPOSE 80

CMD ["apache2-foreground"]
