(** Helpers to work with Microsft Azure AD 

    Convenience module to work with Microsft Azure AD
    *)

val make :
  kv:(module KeyValue.KV with type store = 'store and type value = string) ->
  store:'store ->
  app_id:string ->
  tenant_id:'a ->
  secret:string option ->
  redirect_uri:Uri.t ->
  'store Static.t
(** Creates a static Client configured for Microsft Azure AD *)
