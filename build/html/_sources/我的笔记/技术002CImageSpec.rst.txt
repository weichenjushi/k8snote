技术002CImageSpec

技术002CImageSpec
=================

[]

Image Manifest - a document describing the components that make up a
container image 描述了容器镜像的组件

-  mediaType

application/vnd.oci.image.layer.v1.tar
application/vnd.oci.image.layer.v1.tar+gzip
application/vnd.oci.image.layer.nondistributable.v1.tar
application/vnd.oci.image.layer.nondistributable.v1.tar+gzip Image Index
- an annotated index of image manifests Image Layout - a filesystem
layout representing the contents of an image

-  镜像每层的内容可能类似tar,zip的压缩文件，nfs的共享文件或者http/ftp/rsync的网络文件
-  +gzip Media Types

The media type application/vnd.oci.image.layer.v1.tar+gzip represents an
application/vnd.oci.image.layer.v1.tar payload which has been compressed
with gzip.

The media type
application/vnd.oci.image.layer.nondistributable.v1.tar+gzip represents
an application/vnd.oci.image.layer.nondistributable.v1.tar payload which
has been compressed with gzip.

-  +zstd Media Types

The media type application/vnd.oci.image.layer.v1.tar+zstd represents an
application/vnd.oci.image.layer.v1.tar payload which has been compressed
with zstd.

The media type
application/vnd.oci.image.layer.nondistributable.v1.tar+zstd represents
an application/vnd.oci.image.layer.nondistributable.v1.tar payload which
has been compressed with zstd.

-  Distributable Format

Layer Changesets for the media type
application/vnd.oci.image.layer.v1.tar MUST be packaged in tar archive.

Layer Changesets for the media type
application/vnd.oci.image.layer.v1.tar MUST NOT include duplicate
entries for file paths in the resulting tar archive.

-  File Types支持的文件类型

regular files directories sockets symbolic links block devices character
devices FIFOs

-  Non-Distributable Layers

Due to legal requirements, certain layers may not be regularly
distributable. Such “non-distributable” layers are typically downloaded
directly from a distributor but never uploaded.

Non-distributable layers SHOULD be tagged with an alternative mediatype
of application/vnd.oci.image.layer.nondistributable.v1.tar.
Implementations SHOULD NOT upload layers tagged with this media type;
however, such a media type SHOULD NOT affect whether an implementation
downloads the layer.

Descriptors referencing non-distributable layers MAY include urls for
downloading these layers directly; however, the presence of the urls
field SHOULD NOT be used to determine whether or not a layer is
non-distributable.

Filesystem Layer - a changeset that describes a container’s filesystem
该文档描述了如何序列化文件和文件的变化比如移除文件放到一个blob称layer。

Image Configuration - a document determining layer ordering and
configuration of the image suitable for translation into a runtime
bundle 定义了layer的顺序和将image转换成运行的bundle

-  OCI
   镜像是一个有序的文件层的集合和在容器运行环境中根据执行参数而改变。
-  Layer

Image filesystems are composed of layers.

Each layer represents a set of filesystem changes in a tar-based layer
format, recording files to be added, changed, or deleted relative to its
parent layer. 每层是根据父层记录文件的增加修改和删除。

Layers do not have configuration metadata such as environment variables
or default arguments - these are properties of the image as a whole
rather than any particular layer.
层没有配置环境变量等元数据，环境变量是针对整个镜像而不是单个层的。

Using a layer-based or union filesystem such as AUFS, or by computing
the diff from filesystem snapshots, the filesystem changeset can be used
to present a series of image layers as if they were one cohesive
filesystem.
通过计算文件系统快照的不同，文件系统改变集合代表一系列的镜像层。

-  Image JSON

Each image has an associated JSON structure which describes some basic
information about the image such as date created, author, as well as
execution/runtime configuration like its entrypoint, default arguments,
networking, and volumes.
每个镜像文件有一个JSON结构的文件，信息包括创建时间，作者，以及entrypoint和默认的参数、网络、volume等。

The JSON structure also references a cryptographic hash of each layer
used by the image, and provides history information for those layers.

This JSON is considered to be immutable, because changing it would
change the computed ImageID.

Changing it means creating a new derived image, instead of changing the
existing image.

-  Layer DiffID
-  Layer ChainID 根据Ln层生成Ln+1层的chainID

ChainID(L₀) = DiffID(L₀) ChainID(L₀|…|Lₙ₋₁|Lₙ) =
Digest(ChainID(L₀|…|Lₙ₋₁) + " " + DiffID(Lₙ))

Let’s expand the definition of ChainID(A|B|C) to explore its internal
structure:

ChainID(A) = DiffID(A) ChainID(A|B) = Digest(ChainID(A) + " " +
DiffID(B)) ChainID(A|B|C) = Digest(ChainID(A|B) + " " + DiffID(C))

-  ImageID 每个镜像ID是它的配置文件的SHA256的hash值。
-  Properties

Note: Any OPTIONAL field MAY also be set to null, which is equivalent to
being absent.

created string, OPTIONAL

An combined date and time at which the image was created, formatted as
defined by RFC 3339, section 5.6.

author string, OPTIONAL

Gives the name and/or email address of the person or entity which
created and is responsible for maintaining the image.

architecture string, REQUIRED

The CPU architecture which the binaries in this image are built to run
on. Configurations SHOULD use, and implementations SHOULD understand,
values listed in the Go Language document for GOARCH.

os string, REQUIRED

The name of the operating system which the image is built to run on.
Configurations SHOULD use, and implementations SHOULD understand, values
listed in the Go Language document for GOOS.

config object, OPTIONAL

The execution parameters which SHOULD be used as a base when running a
container using the image. This field can be null, in which case any
execution parameters should be specified at creation of the container.

User string, OPTIONAL

The username or UID which is a platform-specific structure that allows
specific control over which user the process run as. This acts as a
default value to use when the value is not specified when creating a
container. For Linux based systems, all of the following are valid:
user, uid, user:group, uid:gid, uid:group, user:gid. If group/gid is not
specified, the default group and supplementary groups of the given
user/uid in /etc/passwd from the container are applied.

ExposedPorts object, OPTIONAL

A set of ports to expose from a container running this image. Its keys
can be in the format of: port/tcp, port/udp, port with the default
protocol being tcp if not specified. These values act as defaults and
are merged with any specified when creating a container. NOTE: This JSON
structure value is unusual because it is a direct JSON serialization of
the Go type map[string]struct{} and is represented in JSON as an object
mapping its keys to an empty object.

Env array of strings, OPTIONAL

Entries are in the format of VARNAME=VARVALUE. These values act as
defaults and are merged with any specified when creating a container.

Entrypoint array of strings, OPTIONAL

A list of arguments to use as the command to execute when the container
starts. These values act as defaults and may be replaced by an
entrypoint specified when creating a container.

Cmd array of strings, OPTIONAL

Default arguments to the entrypoint of the container. These values act
as defaults and may be replaced by any specified when creating a
container. If an Entrypoint value is not specified, then the first entry
of the Cmd array SHOULD be interpreted as the executable to run.

Volumes object, OPTIONAL

A set of directories describing where the process is likely write data
specific to a container instance. NOTE: This JSON structure value is
unusual because it is a direct JSON serialization of the Go type
map[string]struct{} and is represented in JSON as an object mapping its
keys to an empty object.

WorkingDir string, OPTIONAL

Sets the current working directory of the entrypoint process in the
container. This value acts as a default and may be replaced by a working
directory specified when creating a container.

Labels object, OPTIONAL

The field contains arbitrary metadata for the container. This property
MUST use the annotation rules.

StopSignal string, OPTIONAL

The field contains the system call signal that will be sent to the
container to exit. The signal can be a signal name in the format
SIGNAME, for instance SIGKILL or SIGRTMIN+3.

rootfs object, REQUIRED

The rootfs key references the layer content addresses used by the image.
This makes the image config hash depend on the filesystem hash.

type string, REQUIRED

MUST be set to layers. Implementations MUST generate an error if they
encounter a unknown value while verifying or unpacking an image.

diff_ids array of strings, REQUIRED An array of layer content hashes
(DiffIDs), in order from first to last. history array of objects,
OPTIONAL

Describes the history of each layer. The array is ordered from first to
last. The object has the following fields:

created string, OPTIONAL

A combined date and time at which the layer was created, formatted as
defined by RFC 3339, section 5.6.

author string, OPTIONAL The author of the build point. created_by
string, OPTIONAL The command which created the layer. comment string,
OPTIONAL A custom message set when creating the layer. empty_layer
boolean, OPTIONAL

This field is used to mark if the history item created a filesystem
diff. It is set to true if this history item doesn’t correspond to an
actual layer in the rootfs section (for example, Dockerfile’s ENV
command results in no change to the filesystem).

Any extra fields in the Image JSON struct are considered implementation
specific and MUST be ignored by any implementations which are unable to
interpret them.

Whitespace is OPTIONAL and implementations MAY have compact JSON with no
whitespace.

Conversion - a document describing how this translation should occur

Descriptor - a reference that describes the type, metadata and content
address of referenced content

-  OCI镜像的层是通过Merkle树有向无循环调度来组织的。
