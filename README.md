# DOCKER VOLUME BACKUPS

Este script sirve para realizar backups de volumenes de contenedores docker de maquinas remotas.

# USO

- Descargar este repositorio en la maquina donde se quieren almacenar los backups.

- Es necesario copiar la clave publica del usuario con permisos para realizar el backup en la maquina docker host donde tenemos los volumenes, si lo hiciesemos con root tendriamos que acceder como root a /root/.ssh en la maquina donde queremos guardar los logs y copiar el contenido de id_rsa.pub. Luego acceder a la maquina docker host y copiar el contenido que hemos copiado en /root/.ssh/authorized_keys.

```*Si no tuvieramos el archivo id_rsa.pub en la maquina donde queremos copiar los backups, tedriamos que loguearnos como root en la misma y ejecutar ssh-keygen.```

- Guardar los datos de los backups en el archivo backups.csv (se incluyen unas lineas de ejemplo)
