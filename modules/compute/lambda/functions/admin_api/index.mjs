import {
  S3Client,
  ListObjectsV2Command,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import {
  success,
  notFound,
  handleApiError,
} from "/opt/nodejs/helper.mjs";
import { log } from "/opt/nodejs/logger.mjs";

const s3 = new S3Client({ region: process.env.REGION || process.env.AWS_REGION });
const BUCKET = process.env.CONTEXT_BUCKET;

export const handler = async (event) => {
  try {
    const method = event.httpMethod;
    const path = event.path;
    const id = event.pathParameters?.id;

    // Health check
    if (method === "GET" && path === "/health") {
      return success({ status: "ok", service: "agent-context-admin-api" });
    }

    // List contexts
    if (method === "GET" && path.endsWith("/context") && !id) {
      return await listContexts();
    }

    // Get single context
    if (method === "GET" && id) {
      return await getContext(id);
    }

    return notFound(`No handler for ${method} ${path}`);
  } catch (error) {
    return handleApiError(error, "in admin_api handler");
  }
};

async function listContexts() {
  log.info(`Listing contexts from bucket ${BUCKET}`);
  const { Contents = [] } = await s3.send(
    new ListObjectsV2Command({ Bucket: BUCKET }),
  );

  const items = Contents.filter((o) => o.Key && o.Key.endsWith(".json"))
    .map((o) => ({
      id: o.Key.replace(/\.json$/, ""),
      lastModified: o.LastModified,
      size: o.Size,
    }))
    .sort((a, b) => new Date(b.lastModified) - new Date(a.lastModified));

  return success({ count: items.length, items });
}

async function getContext(id) {
  log.info(`Fetching context ${id} from bucket ${BUCKET}`);
  try {
    const { Body } = await s3.send(
      new GetObjectCommand({ Bucket: BUCKET, Key: `${id}.json` }),
    );
    const body = await Body.transformToString();
    return success({ id, data: JSON.parse(body) });
  } catch (error) {
    if (error.name === "NoSuchKey") {
      return notFound(`Context ${id} not found`);
    }
    throw error;
  }
}
