/*
 * Spotlight plugin for MailSpool
 * Copyright 2005 by Yoshida Masato <yoshidam@yoshidam.net> 
 */

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include "ruby.h"
#include "st.h"

#define RUBY_SCRIPT_NAME "GetMetadataForFile"
#define RUBY_SCRIPT_OPT "-Ku"
#define RUBY_FUNC_NAME "GetMetadataForFile"

#define PLUGIN_NAME "MailSpool.importer"
#define MAIL_SPOOL_PATH "/Mail/"
#define PLUGIN_ID "net.yoshidam.MailSpool"


// call Ruby importer
static VALUE call_rbGetMetadataForFile(VALUE arg) {
  ID funname = rb_intern(RUBY_FUNC_NAME);
  return rb_funcall(rb_mKernel, funname, 3,
                    rb_ary_entry(arg, 0),
                    rb_ary_entry(arg, 1),
                    rb_ary_entry(arg, 2));
}

// rescue Ruby exception
static VALUE rescue_rbGetMetadataForFile(VALUE arg) {
  fprintf(stderr, PLUGIN_NAME " exception: %s\n", StringValuePtr(ruby_errinfo));
  return Qnil;
}

// convert Hash into CFDictionary
static int hash_conv(VALUE key, VALUE val, CFMutableDictionaryRef dict) {
  CFStringRef cfkey;
  CFStringRef cfval;

  if (TYPE(key) != T_STRING)
    key = rb_funcall(key, rb_intern("to_s"), 0);
  else
    key = StringValue(key);
  if (TYPE(val) != T_STRING)
    key = rb_funcall(val, rb_intern("to_s"), 0);
  else
    val = StringValue(val);

  cfkey = CFStringCreateWithBytes(NULL,
                                  (UInt8*)RSTRING(key)->ptr,
                                  RSTRING(key)->len,
                                  kCFStringEncodingUTF8, TRUE);
  if (!cfkey)
    return ST_STOP;
  cfval = CFStringCreateWithBytes(NULL,
                                  (UInt8*)RSTRING(val)->ptr,
                                  RSTRING(val)->len,
                                  kCFStringEncodingUTF8, TRUE);
  if (!cfval) {
    CFRelease(cfkey);
    return ST_STOP;
  }
  CFDictionarySetValue(dict, cfkey, cfval);
  CFRelease(cfkey);
  CFRelease(cfval);

  return ST_CONTINUE;
}

// convert Ruby VALUE into CFTypeRef
static CFTypeRef convert_value(VALUE val) {
  CFTypeRef ret = NULL;
  volatile VALUE cTime = rb_const_get(rb_cObject, rb_intern("Time"));

  switch (TYPE(val)) {
    case T_NIL:
    case T_FALSE:
#ifdef DEBUG
      fprintf(stderr, "Nil\n");
#endif
      break;
    case T_ARRAY: {
      int len = RARRAY(val)->len;
      int i;
#ifdef DEBUG
      volatile VALUE sval = rb_funcall(val, rb_intern("inspect"), 0);
      fprintf(stderr, "Array: %s\n", StringValuePtr(sval));
#endif
      ret = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
      if (!ret)
        return NULL;
      for (i = 0; i < len; i++) {
        CFStringRef cfstr;
        volatile VALUE sval = RARRAY(val)->ptr[i]; 
        if (TYPE(sval) != T_STRING)
          sval = rb_funcall(sval, rb_intern("to_s"), 0);
        else
          sval = StringValue(sval);
        cfstr = CFStringCreateWithBytes(NULL,
                                        (UInt8*)RSTRING(sval)->ptr,
                                        RSTRING(sval)->len,
                                        kCFStringEncodingUTF8, TRUE);
        if (!cfstr) {
          CFRelease(ret);
          return NULL;
        }
        CFArrayAppendValue((CFMutableArrayRef)ret, cfstr);
        CFRelease(cfstr);
      }
      break;
    }
    case T_HASH: {
      st_table* table = RHASH(val)->tbl;
#ifdef DEBUG
      volatile VALUE sval = rb_funcall(val, rb_intern("inspect"), 0);
      fprintf(stderr, "Hash: %s\n", StringValuePtr(sval));
#endif
      ret = CFDictionaryCreateMutable(NULL, 0,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
      if (!ret)
        return NULL;
      st_foreach(table, hash_conv, (st_data_t)ret);
      break;
    }
    case T_FIXNUM: {
      int i = NUM2INT(val);
#ifdef DEBUG
      fprintf(stderr, "Fixnum: %d\n", i);
#endif
      ret = CFNumberCreate(NULL, kCFNumberIntType, &i);
      break;
    }
    case T_BIGNUM: {
      long long l = NUM2ULONG(val);
#ifdef DEBUG
      fprintf(stderr, "Integer: %llu\n", l);
#endif
      ret = CFNumberCreate(NULL, kCFNumberLongLongType, &l);
      break;
    }
    case T_FLOAT: {
      double f = NUM2DBL(val);
#ifdef DEBUG
      fprintf(stderr, "Float: %f\n", f);
#endif
      ret = CFNumberCreate(NULL, kCFNumberDoubleType, &f);
      break;
    }
    case T_STRING: {
      volatile VALUE sval = StringValue(val);
#ifdef DEBUG
      fprintf(stderr, "String: %s\n", RSTRING(sval)->ptr);
#endif
      ret = CFStringCreateWithBytes(NULL,
                                    (UInt8*)RSTRING(sval)->ptr,
                                    RSTRING(sval)->len,
                                    kCFStringEncodingUTF8, TRUE);
      break;
    }
    default:
      if (rb_class_of(val) == cTime) {
        VALUE ival = rb_funcall(val, rb_intern("to_i"), 0);
#ifdef DEBUG
        fprintf(stderr, "Time: %lf\n", NUM2DBL(ival));
#endif
        ret = CFDateCreate(NULL, NUM2DBL(ival) - 978307200); // epoch: 2001-01-01 00:00:00 GMT
      }
      else {
        volatile VALUE sval = rb_funcall(val, rb_intern("to_s"), 0);
#ifdef DEBUG
        fprintf(stderr, "UnkownObject(%x): %s\n", TYPE(val), StringValuePtr(sval));
#endif
        ret = CFStringCreateWithBytes(NULL,
                                      (UInt8*)RSTRING(sval)->ptr,
                                      RSTRING(sval)->len,
                                      kCFStringEncodingUTF8, TRUE);
      }
  }
  return ret;
}

// add VALUE to CFDictionary if no such key already exists
static VALUE dict_add_value(VALUE obj, VALUE key, VALUE val) {
  CFMutableDictionaryRef attr;
  Data_Get_Struct(obj, struct __CFDictionary, attr);
  volatile VALUE skey = StringValue(key);
  CFTypeRef cfref = convert_value(val);
  if (cfref) {
    CFStringRef cfkey = CFStringCreateWithBytes(NULL,
                                                (UInt8*)RSTRING(skey)->ptr,
                                                RSTRING(skey)->len,
                                                kCFStringEncodingUTF8, TRUE);
    CFDictionaryAddValue(attr, cfkey, cfref);
    CFRelease(cfkey);
    CFRelease(cfref);
  }
  return obj;
}

// set VALUE to CFDictionary
static VALUE dict_set_value(VALUE obj, VALUE key, VALUE val) {
  CFMutableDictionaryRef attr;
  Data_Get_Struct(obj, struct __CFDictionary, attr);
  volatile VALUE skey = StringValue(key);
  CFTypeRef cfref = convert_value(val);
  if (cfref) {
    CFStringRef cfkey = CFStringCreateWithBytes(NULL,
                                                (UInt8*)RSTRING(skey)->ptr,
                                                RSTRING(skey)->len,
                                                kCFStringEncodingUTF8, TRUE);
    CFDictionarySetValue(attr, cfkey, cfref);
    CFRelease(cfkey);
    CFRelease(cfref);
  }
  return obj;
}

void
sigint_handler(int sig) {
  ruby_stop(0);
}

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
  static int ruby_initialized = 0;
  static VALUE cDictionary;
  CFRange range;
  CFIndex pos;
  CFIndex len = CFStringGetLength(pathToFile);
  CFBundleRef b;
  CFURLRef resurl;
  UInt8 pathbuf[FILENAME_MAX];
  const char* uti;
  const char* path;
  char utiBuf[FILENAME_MAX];
  char pathBuf[FILENAME_MAX];
  volatile VALUE arg;
  volatile VALUE obj;
  VALUE ret;

  // path check
  range = CFStringFind(pathToFile, CFSTR(MAIL_SPOOL_PATH), 0);
  if (range.location == kCFNotFound)
    return FALSE;
    
  // file name check
  for (pos = len - 1; pos >= 0; pos--) {
    UniChar c = CFStringGetCharacterAtIndex(pathToFile, pos);
    if (c == '/')
      break;
    else if (c < '0' || c > '9')
      return FALSE;
  }

  // get script path
  b = CFBundleGetBundleWithIdentifier(CFSTR(PLUGIN_ID));
  if (b) {
    resurl = CFBundleCopyResourcesDirectoryURL(b);
    CFURLGetFileSystemRepresentation(resurl, TRUE, pathbuf, sizeof(pathbuf));
  }

  if (!ruby_initialized) {
    char* args[6];
    args[0] = PLUGIN_NAME;
    args[1] = RUBY_SCRIPT_OPT;
    args[2] = "-I";
    args[3] = (char*)pathbuf;
    args[4] = "-r" RUBY_SCRIPT_NAME;
    args[5] = "-e0";

    // initialize Ruby interpreter
    ruby_init();
    ruby_options(6, args);
    ruby_script(RUBY_SCRIPT_NAME);

    // define private class
    cDictionary = rb_define_class("__MD_Dictionary", rb_cObject);
    rb_define_method(cDictionary, "add_value", dict_add_value, 2);
    rb_define_method(cDictionary, "set_value", dict_set_value, 2);
    rb_define_method(cDictionary, "[]=", dict_set_value, 2);

    signal(SIGINT, sigint_handler);

    ruby_initialized = 1;
  }
  else
    rb_gc_start();
  
  obj = Data_Wrap_Struct(cDictionary, 0, 0, attributes);

  // setup function parameters
  arg = rb_ary_new();
  rb_ary_push(arg, obj);
  uti = CFStringGetCStringPtr(contentTypeUTI, kCFStringEncodingUTF8);
  if (!uti) {
    CFStringGetCString(contentTypeUTI, utiBuf, sizeof(utiBuf), kCFStringEncodingUTF8);
	uti = utiBuf;
  }
  path = CFStringGetCStringPtr(pathToFile, kCFStringEncodingUTF8);
  if (!path) {
    CFStringGetCString(pathToFile, pathBuf, sizeof(pathBuf), kCFStringEncodingUTF8);
	path = pathBuf;
  }
  rb_ary_push(arg, rb_str_new2(uti));
  rb_ary_push(arg, rb_str_new2(path));

  // call Ruby script
  ret = rb_rescue(call_rbGetMetadataForFile, arg, rescue_rbGetMetadataForFile, Qnil);
#ifdef DEBUG
  fprintf(stderr, PLUGIN_NAME ": script %s\n",
          (ret != Qnil && ret != Qfalse) ? "success" : "failed");
#endif
  if (ret != Qnil && ret != Qfalse)
    return TRUE;
    
  return FALSE;
}
