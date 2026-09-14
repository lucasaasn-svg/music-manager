# Music Manager V5 — GitHub Pages + Supabase

Esta versão mantém a ideia visual do Music Manager V4 e adiciona:

- Login e cadastro reais com Supabase Auth
- Usuários persistentes na nuvem
- Catálogo de músicas compartilhado
- Painel Admin
- Upload de MP3/áudio
- Upload de capa
- Exclusão de músicas pelo Admin
- Curtidas salvas por usuário
- Player online
- Layout responsivo para celular, tablet e PC
- PWA/manifest
- Marca d'água: Duster-x Productions

## 1. Criar o projeto Supabase

Crie um projeto em https://supabase.com/

Depois abra o SQL Editor e execute TODO o arquivo:

`supabase.sql`

## 2. Criar sua conta

Abra o site, clique em "Criar conta" e faça seu cadastro.

Se o Supabase estiver configurado para confirmar e-mail, confirme o e-mail antes de entrar.

## 3. Virar administrador

No Supabase:

Authentication > Users

Copie o UUID do seu usuário.

Depois volte ao SQL Editor e execute:

update public.profiles
set is_admin = true
where id = 'SEU_UUID_AQUI';

## 4. Colocar as chaves no site

Abra `index.html` e procure:

const SUPABASE_URL = "https://czqoistrpyzzafnrnwex.supabase.co";
const SUPABASE_KEY = "A chave publishable já está configurada no index.html deste pacote.";

Troque pelos dados do seu projeto.

Use a chave pública/publishable/anon apropriada para aplicações no navegador.

NUNCA coloque a service_role key no index.html.

## 5. Mandar para o GitHub

Coloque estes arquivos na raiz do seu repositório:

- index.html
- manifest.webmanifest
- icon.svg
- sw.js
- .nojekyll
- supabase.sql
- README.md

O `supabase.sql` é documentação/setup e não é executado pelo GitHub Pages.

Depois:

Settings > Pages

Source: Deploy from a branch
Branch: main
Folder: /(root)
Save

Seu site ficará em:

https://SEU_USUARIO.github.io/music-manager/

## 6. Como adicionar uma música

Depois de virar administrador:

1. Entre no Music Manager.
2. Abra "Painel Admin".
3. Preencha título e artista.
4. Escolha o MP3.
5. Opcionalmente escolha uma capa.
6. Clique em "Enviar música".
7. A música é enviada para o Storage do Supabase.
8. O registro é salvo no banco.
9. Todos os usuários passam a enxergar a música no catálogo.

## Observação sobre arquivos de áudio

Para arquivos grandes, o Supabase recomenda upload resumível (TUS) em vez do upload padrão. Esta primeira V5 usa o upload padrão para manter o projeto simples. Para uma biblioteca grande de músicas, a próxima versão pode trocar o uploader por upload resumível.

## Direitos autorais

Use somente músicas que você tenha autorização/licença para distribuir e transmitir. O projeto não fornece catálogo comercial de terceiros.

## Estrutura

- `index.html` — aplicação inteira
- `supabase.sql` — tabelas, RLS, buckets e políticas
- `manifest.webmanifest` — instalação como PWA
- `sw.js` — cache básico
- `icon.svg` — ícone
- `.nojekyll` — evita processamento Jekyll desnecessário


## Configuração preparada

Este pacote já está configurado para o projeto Supabase `czqoistrpyzzafnrnwex`. A chave usada no navegador é a chave publishable, apropriada para uso público quando as políticas RLS estão configuradas corretamente.
