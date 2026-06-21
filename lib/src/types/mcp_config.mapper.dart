// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mcp_config.dart';

class McpServerConfigMapper extends ClassMapperBase<McpServerConfig> {
  McpServerConfigMapper._();

  static McpServerConfigMapper? _instance;
  static McpServerConfigMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = McpServerConfigMapper._());
      McpStdioServerMapper.ensureInitialized();
      McpStreamableHttpServerMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'McpServerConfig';

  static String _$name(McpServerConfig v) => v.name;
  static const Field<McpServerConfig, String> _f$name = Field('name', _$name);
  static int? _$timeoutSeconds(McpServerConfig v) => v.timeoutSeconds;
  static const Field<McpServerConfig, int> _f$timeoutSeconds = Field(
    'timeoutSeconds',
    _$timeoutSeconds,
    opt: true,
  );
  static List<String>? _$enabledTools(McpServerConfig v) => v.enabledTools;
  static const Field<McpServerConfig, List<String>> _f$enabledTools = Field(
    'enabledTools',
    _$enabledTools,
    opt: true,
  );
  static List<String>? _$disabledTools(McpServerConfig v) => v.disabledTools;
  static const Field<McpServerConfig, List<String>> _f$disabledTools = Field(
    'disabledTools',
    _$disabledTools,
    opt: true,
  );

  @override
  final MappableFields<McpServerConfig> fields = const {
    #name: _f$name,
    #timeoutSeconds: _f$timeoutSeconds,
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
  };

  static McpServerConfig _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'McpServerConfig',
      'type',
      '${data.value['type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static McpServerConfig fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<McpServerConfig>(map);
  }

  static McpServerConfig fromJson(String json) {
    return ensureInitialized().decodeJson<McpServerConfig>(json);
  }
}

mixin McpServerConfigMappable {
  String toJson();
  Map<String, dynamic> toMap();
  McpServerConfigCopyWith<McpServerConfig, McpServerConfig, McpServerConfig>
      get copyWith;
}

abstract class McpServerConfigCopyWith<$R, $In extends McpServerConfig, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get enabledTools;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get disabledTools;
  $R call({
    String? name,
    int? timeoutSeconds,
    List<String>? enabledTools,
    List<String>? disabledTools,
  });
  McpServerConfigCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class McpStdioServerMapper extends SubClassMapperBase<McpStdioServer> {
  McpStdioServerMapper._();

  static McpStdioServerMapper? _instance;
  static McpStdioServerMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = McpStdioServerMapper._());
      McpServerConfigMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'McpStdioServer';

  static String _$name(McpStdioServer v) => v.name;
  static const Field<McpStdioServer, String> _f$name = Field('name', _$name);
  static String _$command(McpStdioServer v) => v.command;
  static const Field<McpStdioServer, String> _f$command = Field(
    'command',
    _$command,
  );
  static List<String> _$args(McpStdioServer v) => v.args;
  static const Field<McpStdioServer, List<String>> _f$args = Field(
    'args',
    _$args,
    opt: true,
  );
  static Map<String, String>? _$env(McpStdioServer v) => v.env;
  static const Field<McpStdioServer, Map<String, String>> _f$env = Field(
    'env',
    _$env,
    opt: true,
  );
  static int? _$timeoutSeconds(McpStdioServer v) => v.timeoutSeconds;
  static const Field<McpStdioServer, int> _f$timeoutSeconds = Field(
    'timeoutSeconds',
    _$timeoutSeconds,
    key: r'timeout_seconds',
    opt: true,
  );
  static List<String>? _$enabledTools(McpStdioServer v) => v.enabledTools;
  static const Field<McpStdioServer, List<String>> _f$enabledTools = Field(
    'enabledTools',
    _$enabledTools,
    key: r'enabled_tools',
    opt: true,
  );
  static List<String>? _$disabledTools(McpStdioServer v) => v.disabledTools;
  static const Field<McpStdioServer, List<String>> _f$disabledTools = Field(
    'disabledTools',
    _$disabledTools,
    key: r'disabled_tools',
    opt: true,
  );

  @override
  final MappableFields<McpStdioServer> fields = const {
    #name: _f$name,
    #command: _f$command,
    #args: _f$args,
    #env: _f$env,
    #timeoutSeconds: _f$timeoutSeconds,
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'stdio';
  @override
  late final ClassMapperBase superMapper =
      McpServerConfigMapper.ensureInitialized();

  static McpStdioServer _instantiate(DecodingData data) {
    return McpStdioServer(
      name: data.dec(_f$name),
      command: data.dec(_f$command),
      args: data.dec(_f$args),
      env: data.dec(_f$env),
      timeoutSeconds: data.dec(_f$timeoutSeconds),
      enabledTools: data.dec(_f$enabledTools),
      disabledTools: data.dec(_f$disabledTools),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static McpStdioServer fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<McpStdioServer>(map);
  }

  static McpStdioServer fromJson(String json) {
    return ensureInitialized().decodeJson<McpStdioServer>(json);
  }
}

mixin McpStdioServerMappable {
  String toJson() {
    return McpStdioServerMapper.ensureInitialized().encodeJson<McpStdioServer>(
      this as McpStdioServer,
    );
  }

  Map<String, dynamic> toMap() {
    return McpStdioServerMapper.ensureInitialized().encodeMap<McpStdioServer>(
      this as McpStdioServer,
    );
  }

  McpStdioServerCopyWith<McpStdioServer, McpStdioServer, McpStdioServer>
      get copyWith =>
          _McpStdioServerCopyWithImpl<McpStdioServer, McpStdioServer>(
            this as McpStdioServer,
            $identity,
            $identity,
          );
  @override
  String toString() {
    return McpStdioServerMapper.ensureInitialized().stringifyValue(
      this as McpStdioServer,
    );
  }

  @override
  bool operator ==(Object other) {
    return McpStdioServerMapper.ensureInitialized().equalsValue(
      this as McpStdioServer,
      other,
    );
  }

  @override
  int get hashCode {
    return McpStdioServerMapper.ensureInitialized().hashValue(
      this as McpStdioServer,
    );
  }
}

extension McpStdioServerValueCopy<$R, $Out>
    on ObjectCopyWith<$R, McpStdioServer, $Out> {
  McpStdioServerCopyWith<$R, McpStdioServer, $Out> get $asMcpStdioServer =>
      $base.as((v, t, t2) => _McpStdioServerCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class McpStdioServerCopyWith<$R, $In extends McpStdioServer, $Out>
    implements McpServerConfigCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get args;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>? get env;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get enabledTools;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get disabledTools;
  @override
  $R call({
    String? name,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    int? timeoutSeconds,
    List<String>? enabledTools,
    List<String>? disabledTools,
  });
  McpStdioServerCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _McpStdioServerCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, McpStdioServer, $Out>
    implements McpStdioServerCopyWith<$R, McpStdioServer, $Out> {
  _McpStdioServerCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<McpStdioServer> $mapper =
      McpStdioServerMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get args =>
      ListCopyWith(
        $value.args,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(args: v),
      );
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get env => $value.env != null
          ? MapCopyWith(
              $value.env!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(env: v),
            )
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get enabledTools => $value.enabledTools != null
          ? ListCopyWith(
              $value.enabledTools!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(enabledTools: v),
            )
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get disabledTools => $value.disabledTools != null
          ? ListCopyWith(
              $value.disabledTools!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(disabledTools: v),
            )
          : null;
  @override
  $R call({
    String? name,
    String? command,
    Object? args = $none,
    Object? env = $none,
    Object? timeoutSeconds = $none,
    Object? enabledTools = $none,
    Object? disabledTools = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (command != null) #command: command,
          if (args != $none) #args: args,
          if (env != $none) #env: env,
          if (timeoutSeconds != $none) #timeoutSeconds: timeoutSeconds,
          if (enabledTools != $none) #enabledTools: enabledTools,
          if (disabledTools != $none) #disabledTools: disabledTools,
        }),
      );
  @override
  McpStdioServer $make(CopyWithData data) => McpStdioServer(
        name: data.get(#name, or: $value.name),
        command: data.get(#command, or: $value.command),
        args: data.get(#args, or: $value.args),
        env: data.get(#env, or: $value.env),
        timeoutSeconds: data.get(#timeoutSeconds, or: $value.timeoutSeconds),
        enabledTools: data.get(#enabledTools, or: $value.enabledTools),
        disabledTools: data.get(#disabledTools, or: $value.disabledTools),
      );

  @override
  McpStdioServerCopyWith<$R2, McpStdioServer, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) =>
      _McpStdioServerCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class McpStreamableHttpServerMapper
    extends SubClassMapperBase<McpStreamableHttpServer> {
  McpStreamableHttpServerMapper._();

  static McpStreamableHttpServerMapper? _instance;
  static McpStreamableHttpServerMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = McpStreamableHttpServerMapper._(),
      );
      McpServerConfigMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'McpStreamableHttpServer';

  static String _$name(McpStreamableHttpServer v) => v.name;
  static const Field<McpStreamableHttpServer, String> _f$name = Field(
    'name',
    _$name,
  );
  static String _$url(McpStreamableHttpServer v) => v.url;
  static const Field<McpStreamableHttpServer, String> _f$url = Field(
    'url',
    _$url,
  );
  static Map<String, String>? _$headers(McpStreamableHttpServer v) => v.headers;
  static const Field<McpStreamableHttpServer, Map<String, String>> _f$headers =
      Field('headers', _$headers, opt: true);
  static double _$timeout(McpStreamableHttpServer v) => v.timeout;
  static const Field<McpStreamableHttpServer, double> _f$timeout = Field(
    'timeout',
    _$timeout,
    opt: true,
    def: 30.0,
  );
  static double _$sseReadTimeout(McpStreamableHttpServer v) => v.sseReadTimeout;
  static const Field<McpStreamableHttpServer, double> _f$sseReadTimeout = Field(
    'sseReadTimeout',
    _$sseReadTimeout,
    key: r'sse_read_timeout',
    opt: true,
    def: 300.0,
  );
  static bool _$terminateOnClose(McpStreamableHttpServer v) =>
      v.terminateOnClose;
  static const Field<McpStreamableHttpServer, bool> _f$terminateOnClose = Field(
    'terminateOnClose',
    _$terminateOnClose,
    key: r'terminate_on_close',
    opt: true,
    def: true,
  );
  static int? _$timeoutSeconds(McpStreamableHttpServer v) => v.timeoutSeconds;
  static const Field<McpStreamableHttpServer, int> _f$timeoutSeconds = Field(
    'timeoutSeconds',
    _$timeoutSeconds,
    key: r'timeout_seconds',
    opt: true,
  );
  static List<String>? _$enabledTools(McpStreamableHttpServer v) =>
      v.enabledTools;
  static const Field<McpStreamableHttpServer, List<String>> _f$enabledTools =
      Field('enabledTools', _$enabledTools, key: r'enabled_tools', opt: true);
  static List<String>? _$disabledTools(McpStreamableHttpServer v) =>
      v.disabledTools;
  static const Field<McpStreamableHttpServer, List<String>> _f$disabledTools =
      Field(
    'disabledTools',
    _$disabledTools,
    key: r'disabled_tools',
    opt: true,
  );

  @override
  final MappableFields<McpStreamableHttpServer> fields = const {
    #name: _f$name,
    #url: _f$url,
    #headers: _f$headers,
    #timeout: _f$timeout,
    #sseReadTimeout: _f$sseReadTimeout,
    #terminateOnClose: _f$terminateOnClose,
    #timeoutSeconds: _f$timeoutSeconds,
    #enabledTools: _f$enabledTools,
    #disabledTools: _f$disabledTools,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = 'type';
  @override
  final dynamic discriminatorValue = 'http';
  @override
  late final ClassMapperBase superMapper =
      McpServerConfigMapper.ensureInitialized();

  static McpStreamableHttpServer _instantiate(DecodingData data) {
    return McpStreamableHttpServer(
      name: data.dec(_f$name),
      url: data.dec(_f$url),
      headers: data.dec(_f$headers),
      timeout: data.dec(_f$timeout),
      sseReadTimeout: data.dec(_f$sseReadTimeout),
      terminateOnClose: data.dec(_f$terminateOnClose),
      timeoutSeconds: data.dec(_f$timeoutSeconds),
      enabledTools: data.dec(_f$enabledTools),
      disabledTools: data.dec(_f$disabledTools),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static McpStreamableHttpServer fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<McpStreamableHttpServer>(map);
  }

  static McpStreamableHttpServer fromJson(String json) {
    return ensureInitialized().decodeJson<McpStreamableHttpServer>(json);
  }
}

mixin McpStreamableHttpServerMappable {
  String toJson() {
    return McpStreamableHttpServerMapper.ensureInitialized()
        .encodeJson<McpStreamableHttpServer>(this as McpStreamableHttpServer);
  }

  Map<String, dynamic> toMap() {
    return McpStreamableHttpServerMapper.ensureInitialized()
        .encodeMap<McpStreamableHttpServer>(this as McpStreamableHttpServer);
  }

  McpStreamableHttpServerCopyWith<McpStreamableHttpServer,
          McpStreamableHttpServer, McpStreamableHttpServer>
      get copyWith => _McpStreamableHttpServerCopyWithImpl<
              McpStreamableHttpServer, McpStreamableHttpServer>(
          this as McpStreamableHttpServer, $identity, $identity);
  @override
  String toString() {
    return McpStreamableHttpServerMapper.ensureInitialized().stringifyValue(
      this as McpStreamableHttpServer,
    );
  }

  @override
  bool operator ==(Object other) {
    return McpStreamableHttpServerMapper.ensureInitialized().equalsValue(
      this as McpStreamableHttpServer,
      other,
    );
  }

  @override
  int get hashCode {
    return McpStreamableHttpServerMapper.ensureInitialized().hashValue(
      this as McpStreamableHttpServer,
    );
  }
}

extension McpStreamableHttpServerValueCopy<$R, $Out>
    on ObjectCopyWith<$R, McpStreamableHttpServer, $Out> {
  McpStreamableHttpServerCopyWith<$R, McpStreamableHttpServer, $Out>
      get $asMcpStreamableHttpServer => $base.as(
            (v, t, t2) =>
                _McpStreamableHttpServerCopyWithImpl<$R, $Out>(v, t, t2),
          );
}

abstract class McpStreamableHttpServerCopyWith<
    $R,
    $In extends McpStreamableHttpServer,
    $Out> implements McpServerConfigCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get headers;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get enabledTools;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get disabledTools;
  @override
  $R call({
    String? name,
    String? url,
    Map<String, String>? headers,
    double? timeout,
    double? sseReadTimeout,
    bool? terminateOnClose,
    int? timeoutSeconds,
    List<String>? enabledTools,
    List<String>? disabledTools,
  });
  McpStreamableHttpServerCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _McpStreamableHttpServerCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, McpStreamableHttpServer, $Out>
    implements
        McpStreamableHttpServerCopyWith<$R, McpStreamableHttpServer, $Out> {
  _McpStreamableHttpServerCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<McpStreamableHttpServer> $mapper =
      McpStreamableHttpServerMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
      get headers => $value.headers != null
          ? MapCopyWith(
              $value.headers!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(headers: v),
            )
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get enabledTools => $value.enabledTools != null
          ? ListCopyWith(
              $value.enabledTools!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(enabledTools: v),
            )
          : null;
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>?
      get disabledTools => $value.disabledTools != null
          ? ListCopyWith(
              $value.disabledTools!,
              (v, t) => ObjectCopyWith(v, $identity, t),
              (v) => call(disabledTools: v),
            )
          : null;
  @override
  $R call({
    String? name,
    String? url,
    Object? headers = $none,
    double? timeout,
    double? sseReadTimeout,
    bool? terminateOnClose,
    Object? timeoutSeconds = $none,
    Object? enabledTools = $none,
    Object? disabledTools = $none,
  }) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (url != null) #url: url,
          if (headers != $none) #headers: headers,
          if (timeout != null) #timeout: timeout,
          if (sseReadTimeout != null) #sseReadTimeout: sseReadTimeout,
          if (terminateOnClose != null) #terminateOnClose: terminateOnClose,
          if (timeoutSeconds != $none) #timeoutSeconds: timeoutSeconds,
          if (enabledTools != $none) #enabledTools: enabledTools,
          if (disabledTools != $none) #disabledTools: disabledTools,
        }),
      );
  @override
  McpStreamableHttpServer $make(CopyWithData data) => McpStreamableHttpServer(
        name: data.get(#name, or: $value.name),
        url: data.get(#url, or: $value.url),
        headers: data.get(#headers, or: $value.headers),
        timeout: data.get(#timeout, or: $value.timeout),
        sseReadTimeout: data.get(#sseReadTimeout, or: $value.sseReadTimeout),
        terminateOnClose:
            data.get(#terminateOnClose, or: $value.terminateOnClose),
        timeoutSeconds: data.get(#timeoutSeconds, or: $value.timeoutSeconds),
        enabledTools: data.get(#enabledTools, or: $value.enabledTools),
        disabledTools: data.get(#disabledTools, or: $value.disabledTools),
      );

  @override
  McpStreamableHttpServerCopyWith<$R2, McpStreamableHttpServer, $Out2>
      $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
          _McpStreamableHttpServerCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
