use master

select *
from (
    select 'kill' as ok,
    t1.session_id,
    t1.request_id,
    t3.hostname,
    t3.loginame,
    t3.login_time,
    cast(t3.waittime as bigint) / 60000  as wait_time,
    cast(t2.cpu_time as bigint) / 60000  as cpu_time,
    cast(t2.total_elapsed_time as bigint) / 60000 as total_elapsed_time,
    --t3.program_name,
    db_name (t3.dbid) as dbname,
    t1.task_alloc  * (8.0/1024.0) as Alocado_MB, --qtd de paginas
    t1.task_dealloc  * (8.0/1024.0)as Desalocado_MB, --qtd de paginas
        (SELECT SUBSTRING(text, t2.statement_start_offset/2 + 1,
              (CASE WHEN statement_end_offset = -1
                  THEN LEN(CONVERT(nvarchar(max),text)) * 2
                       ELSE statement_end_offset
                  END - t2.statement_start_offset)/2)
         FROM sys.dm_exec_sql_text(t2.sql_handle)) AS query_text,
    (SELECT query_plan from sys.dm_exec_query_plan(t2.plan_handle)) as query_plan
    from      (Select session_id, request_id,
    sum(internal_objects_alloc_page_count +   user_objects_alloc_page_count) as task_alloc,
    sum (internal_objects_dealloc_page_count + user_objects_dealloc_page_count) as task_dealloc
           from sys.dm_db_task_space_usage
           group by session_id, request_id) as t1,
           sys.dm_exec_requests as t2,
           sys.sysprocesses as t3
    where
        t3.loginame <> '' and
        t1.session_id = t2.session_id and
        (t1.request_id = t2.request_id) and
        t1.session_id = t3.spid and
        t1.session_id > 50
) A
order by loginame, total_elapsed_time DESC