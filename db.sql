create table cache
(
    `key`      varchar(255) not null
        primary key,
    value      mediumtext   not null,
    expiration bigint       not null
)
    collate = utf8mb4_unicode_ci;

create index cache_expiration_index
    on cache (expiration);

create table cache_locks
(
    `key`      varchar(255) not null
        primary key,
    owner      varchar(255) not null,
    expiration bigint       not null
)
    collate = utf8mb4_unicode_ci;

create index cache_locks_expiration_index
    on cache_locks (expiration);

create table customers
(
    id              bigint unsigned auto_increment
        primary key,
    external_id     varchar(20)  not null,
    created_at      timestamp    null,
    first_name      varchar(150) not null,
    last_name       varchar(150) not null,
    phone           varchar(20)  null,
    email           varchar(100) not null,
    city            varchar(100) null,
    source          varchar(150) not null,
    utm_campaign    varchar(100) null,
    product         varchar(255) not null,
    budget_uah      int          null,
    status          varchar(100) null,
    manager         varchar(100) null,
    comment         text         null,
    next_contact_at datetime     null,
    constraint customers_email_unique
        unique (email),
    constraint customers_external_id_unique
        unique (external_id)
)
    collate = utf8mb4_unicode_ci;

create table failed_jobs
(
    id         bigint unsigned auto_increment
        primary key,
    uuid       varchar(255)                          not null,
    connection varchar(255)                          not null,
    queue      varchar(255)                          not null,
    payload    longtext                              not null,
    exception  longtext                              not null,
    failed_at  timestamp default current_timestamp() not null,
    constraint failed_jobs_uuid_unique
        unique (uuid)
)
    collate = utf8mb4_unicode_ci;

create index failed_jobs_connection_queue_failed_at_index
    on failed_jobs (connection, queue, failed_at);

create table job_batches
(
    id             varchar(255) not null
        primary key,
    name           varchar(255) not null,
    total_jobs     int          not null,
    pending_jobs   int          not null,
    failed_jobs    int          not null,
    failed_job_ids longtext     not null,
    options        mediumtext   null,
    cancelled_at   int          null,
    created_at     int          not null,
    finished_at    int          null
)
    collate = utf8mb4_unicode_ci;

create table jobs
(
    id           bigint unsigned auto_increment
        primary key,
    queue        varchar(255)      not null,
    payload      longtext          not null,
    attempts     smallint unsigned not null,
    reserved_at  int unsigned      null,
    available_at int unsigned      not null,
    created_at   int unsigned      not null
)
    collate = utf8mb4_unicode_ci;

create index jobs_queue_index
    on jobs (queue);

create table migrations
(
    id        int unsigned auto_increment
        primary key,
    migration varchar(255) not null,
    batch     int          not null
)
    collate = utf8mb4_unicode_ci;

create table password_reset_tokens
(
    email      varchar(255) not null
        primary key,
    token      varchar(255) not null,
    created_at timestamp    null
)
    collate = utf8mb4_unicode_ci;

create table sessions
(
    id            varchar(255)    not null
        primary key,
    user_id       bigint unsigned null,
    ip_address    varchar(45)     null,
    user_agent    text            null,
    payload       longtext        not null,
    last_activity int             not null
)
    collate = utf8mb4_unicode_ci;

create index sessions_last_activity_index
    on sessions (last_activity);

create index sessions_user_id_index
    on sessions (user_id);

create table users
(
    id                bigint unsigned auto_increment
        primary key,
    name              varchar(255) not null,
    email             varchar(255) not null,
    email_verified_at timestamp    null,
    password          varchar(255) not null,
    remember_token    varchar(100) null,
    created_at        timestamp    null,
    updated_at        timestamp    null,
    constraint users_email_unique
        unique (email)
)
    collate = utf8mb4_unicode_ci;

