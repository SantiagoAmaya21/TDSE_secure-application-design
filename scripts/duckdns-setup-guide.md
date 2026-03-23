# DuckDNS Setup Guide for AWS Academy
# ====================================

## 🦆 ¿Qué es DuckDNS?
DuckDNS es un servicio DNS gratuito que te permite crear subdominios personalizados que apuntan a IPs dinámicas. Perfecto para EC2 instances en AWS Academy.

## 🎯 Ventajas para tu Proyecto
- **Gratis** - No cuesta nada
- **Fácil configuración** - Solo necesitas login con GitHub/Twitter
- **Soporte HTTPS** - Funciona perfectamente con Let's Encrypt
- **IP dinámica** - Se actualiza automáticamente si cambia la IP

## 📋 Paso a Paso - Configuración Completa

### Paso 1: Crear Cuenta DuckDNS
1. **Ve a:** https://www.duckdns.org/
2. **Login con:** GitHub, Twitter, Reddit, o Google
3. **Crea subdominio:** ej: `santiago-secure-app`
4. **Copia tu token:** Lo necesitarás para los scripts

### Paso 2: Estrategia de Dominios

#### Opción A: Un Dominio (Recomendado)
```bash
Apache:  https://santiago-secure-app.duckdns.org
Spring:  https://santiago-secure-app.duckdns.org:8443
```

#### Opción B: Dos Subdominios
```bash
Apache:  https://apache-santiago.duckdns.org
Spring:  https://spring-santiago.duckdns.org:8443
```

### Paso 3: Configuración AWS Academy

#### Instance 1: Apache Server
```bash
# Conectar a Apache instance
ssh -i your-key.pem ec2-user@<APACHE_PUBLIC_IP>

# Clonar repositorio
git clone https://github.com/SantiagoAmaya21/TDSE_secure-application-design.git
cd TDSE_secure-application-design

# Ejecutar script DuckDNS
bash scripts/aws-deploy-apache-duckdns.sh santiago-secure-app TU_DUCKDNS_TOKEN
```

#### Instance 2: Spring Boot Server
```bash
# Conectar a Spring instance
ssh -i your-key.pem ec2-user@<SPRING_PUBLIC_IP>

# Clonar repositorio
git clone https://github.com/SantiagoAmaya21/TDSE_secure-application-design.git
cd TDSE_secure-application-design

# Deploy Spring Boot
bash scripts/aws-deploy-spring.sh

# Configurar SSL con DuckDNS
bash scripts/setup-ssl-spring-duckdns.sh santiago-secure-app.duckdns.org TU_DUCKDNS_TOKEN
```

### Paso 4: Configuración Frontend

#### Actualizar config.js en Apache
```bash
# En Apache instance
sudo nano /var/www/html/secure-app/config.js

# Cambiar esta línea:
BASE_URL: 'https://santiago-secure-app.duckdns.org:8443'
```

#### Actualizar CORS en Spring
```bash
# En Spring instance
sudo nano /opt/secure-app/application-production.properties

# Cambiar esta línea:
cors.allowed-origins=https://santiago-secure-app.duckdns.org

# Reiniciar servicio
sudo systemctl restart secure-app
```

## 🔧 Comandos Útiles

### Actualizar DuckDNS Manualmente
```bash
# Actualizar IP de Apache
curl "https://www.duckdns.org/update?domains=santiago-secure-app&token=TU_TOKEN&ip=$(curl -s ifconfig.me)"

# Verificar IP actual
curl -s ifconfig.me
```

### Verificar Configuración SSL
```bash
# Apache
sudo systemctl status httpd
sudo certbot certificates

# Spring Boot
sudo systemctl status secure-app
curl -k https://localhost:8443/auth/register
```

### Logs y Troubleshooting
```bash
# Logs Apache
sudo journalctl -u httpd -f
sudo tail -f /var/log/httpd/error_log

# Logs Spring Boot
sudo journalctl -u secure-app -f

# Logs DuckDNS
sudo tail -f /var/log/duckdns-update.log
```

## 🚨 Problemas Comunes y Soluciones

### Problema 1: "DNS propagation failed"
**Causa:** DNS necesita tiempo para propagarse
**Solución:**
```bash
# Esperar más tiempo o verificar manualmente
nslookup santiago-secure-app.duckdns.org
```

### Problema 2: "Let's Encrypt certificate failed"
**Causa:** Puerto 80 bloqueado o DNS no resuelve
**Solución:**
```bash
# Verificar firewall
sudo firewall-cmd --list-all

# Verificar que el dominio resuelva
curl -I http://santiago-secure-app.duckdns.org

# Generar certificado manualmente
sudo certbot --apache -d santiago-secure-app.duckdns.org
```

### Problema 3: "Spring Boot no responde por HTTPS"
**Causa:** Keystore no configurado correctamente
**Solución:**
```bash
# Verificar keystore
ls -la /home/ec2-user/keystore.p12

# Recrear keystore
sudo openssl pkcs12 -export \
  -in /etc/letsencrypt/live/santiago-secure-app.duckdns.org/fullchain.pem \
  -inkey /etc/letsencrypt/live/santiago-secure-app.duckdns.org/privkey.pem \
  -out /home/ec2-user/keystore.p12 \
  -name springboot \
  -password pass:CHANGEME

# Reiniciar servicio
sudo systemctl restart secure-app
```

### Problema 4: "CORS errors en frontend"
**Causa:** Dominios no configurados correctamente
**Solución:**
```bash
# Verificar configuración CORS
sudo cat /opt/secure-app/application-production.properties

# Actualizar dominio correcto
sudo sed -i 's/old-domain.com/santiago-secure-app.duckdns.org/g' /opt/secure-app/application-production.properties
sudo systemctl restart secure-app
```

## 📱 Testing Final

### Checklist de Verificación
- [ ] DuckDNS resuelve correctamente
- [ ] Apache funciona por HTTPS
- [ ] Spring Boot funciona por HTTPS
- [ ] Certificados SSL válidos
- [ ] Frontend carga correctamente
- [ ] Login y registro funcionan
- [ ] No hay errores CORS
- [ ] Todos los endpoints funcionan

### Comandos de Testing
```bash
# Test Apache
curl -I https://santiago-secure-app.duckdns.org

# Test Spring Boot
curl -k https://santiago-secure-app.duckdns.org:8443/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'

# Test completo en browser
# Abrir: https://santiago-secure-app.duckdns.org
# Registrar usuario, login, probar todas las funciones
```

## 🎯 Tips para Presentación

### Screenshots Requeridas
1. **DuckDNS Dashboard** - Mostrar subdominio creado
2. **AWS EC2 Console** - Dos instancias corriendo
3. **Apache HTTPS** - Padlock en browser
4. **Spring Boot HTTPS** - Respuesta API por HTTPS
5. **Application Login** - Pantalla de login
6. **Application Dashboard** - Después de login exitoso
7. **Certificate Details** - Let's Encrypt válido

### Video Demo (5-10 minutos)
1. **Arquitectura** - Explicar 2 servidores separados
2. **DuckDNS** - Mostrar configuración y actualización IP
3. **HTTPS Security** - Mostrar padlocks y certificados
4. **Login Flow** - Registro y login funcionando
5. **API Communication** - Mostrar requests entre frontend y backend
6. **Security Features** - TLS, CORS, authentication

## 📞 Soporte Adicional

- **DuckDNS:** https://www.duckdns.org/
- **Let's Encrypt:** https://letsencrypt.org/docs/
- **AWS Academy:** Revisa tu portal de Academy
- **Troubleshooting:** Revisa logs de Apache y Spring Boot

---

**Nota:** DuckDNS es perfecto para proyectos educativos en AWS Academy porque es gratuito, fácil de configurar, y funciona perfectamente con Let's Encrypt para certificados SSL.
