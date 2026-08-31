import { randomUUID } from "node:crypto";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import {
  created,
  badRequest,
  handleApiError,
} from "/opt/nodejs/helper.mjs";
import { log } from "/opt/nodejs/logger.mjs";

const s3 = new S3Client({ region: process.env.REGION || process.env.AWS_REGION });
const BUCKET = process.env.CONTEXT_BUCKET;

export const handler = async (event) => {
  try {
    if (event.httpMethod !== "POST") {
      return badRequest(`Method ${event.httpMethod} not allowed on this route`);
    }

    let payload;
    try {
      payload = JSON.parse(event.body || "{}");
    } catch {
      return badRequest("Invalid JSON body");
    }

    if (!payload.context || typeof payload.context !== "object") {
      return badRequest("Missing required field: context");
    }

    const id = payload.id || randomUUID();
    const record = {
      id,
      ...payload,
      createdAt: new Date().toISOString(),
    };

    await s3.send(
      new PutObjectCommand({
        Bucket: BUCKET,
        Key: `${id}.json`,
        Body: JSON.stringify(record, null, 2),
        ContentType: "application/json",
      }),
    );

    log.success(`Context ${id} stored in bucket ${BUCKET}`);
    return created({ id, message: "Context stored successfully" });
  } catch (error) {
    return handleApiError(error, "in process_context handler");
  }
};
