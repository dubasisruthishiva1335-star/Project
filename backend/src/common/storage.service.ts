import { Injectable } from '@nestjs/common';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import * as fs from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';

export interface PresignResult {
  uploadUrl: string;
  s3Key: string;
  publicUrl?: string;
  direct: boolean;
}

@Injectable()
export class StorageService {
  private get driver(): string {
    return process.env.STORAGE_DRIVER || 'local';
  }

  private get bucket(): string {
    return process.env.AWS_S3_BUCKET || 'myvault-files-app';
  }

  private get region(): string {
    return process.env.AWS_REGION || 'eu-north-1';
  }

  private get uploadsDir(): string {
    return path.join(process.cwd(), 'uploads');
  }

  private getS3Client(): S3Client {
    const config: any = { region: this.region };
    if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
      config.credentials = {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      };
    }
    return new S3Client(config);
  }

  constructor() {
    if (!fs.existsSync(this.uploadsDir)) {
      fs.mkdirSync(this.uploadsDir, { recursive: true });
    }
  }

  async presign(domain: string, fileName: string, contentType: string): Promise<PresignResult> {
    const key = `${domain}/${Date.now()}-${randomUUID()}-${fileName.replace(/\s+/g, '_')}`;

    if (this.driver === 's3') {
      const s3 = this.getS3Client();
      const putCmd = new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        ContentType: contentType,
        ACL: 'public-read',
      });
      const getCmd = new GetObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });

      const uploadUrl = await getSignedUrl(s3, putCmd, { expiresIn: 900 }); // 15 min upload window
      const publicUrl = await getSignedUrl(s3, getCmd, { expiresIn: 604800 }); // 7-day view/download window

      return {
        uploadUrl,
        s3Key: key,
        publicUrl,
        direct: true,
      };
    }

    return {
      uploadUrl: `/admin/uploads/local/${encodeURIComponent(key)}`,
      s3Key: key,
      publicUrl: `/uploads/${key}`,
      direct: false,
    };
  }

  async writeLocalFile(key: string, buffer: Buffer) {
    const fullPath = path.join(this.uploadsDir, key);
    fs.mkdirSync(path.dirname(fullPath), { recursive: true });
    fs.writeFileSync(fullPath, buffer);
    return `/uploads/${key}`;
  }

  async publicUrlForAsync(key: string): Promise<string> {
    if (this.driver === 's3') {
      const s3 = this.getS3Client();
      const getCmd = new GetObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });
      return getSignedUrl(s3, getCmd, { expiresIn: 604800 });
    }
    return `/uploads/${key}`;
  }

  publicUrlFor(key: string): string {
    if (this.driver === 's3') {
      return `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;
    }
    return `/uploads/${key}`;
  }
}
